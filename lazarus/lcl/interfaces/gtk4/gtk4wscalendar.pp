{
 *****************************************************************************
 *                             Gtk4WSCalendar.pp                             *
 *                             -----------------                             * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit Gtk4WSCalendar;

{$mode objfpc}{$H+}
{$I gtk4defines.inc}

interface

uses
  // Bindings
  LazGlib2, LazGObject2, LazGdk4, LazGtk4, LazGtk4_Compat,
  // RTL, FCL, LCL
  SysUtils, Types, Classes, Controls, Calendar, LCLType,
  InterfaceBase, LCLProc,
  // Widgetset
  WSCalendar, WSLCLClasses, WSProc;

type

  { TGtk4WSCustomCalendar }

  TGtk4WSCustomCalendar = class(TWSCustomCalendar)
  protected
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle; override;
    class function GetDateTime(const ACalendar: TCustomCalendar): TDateTime; override;
    class function HitTest(const ACalendar: TCustomCalendar; const APoint: TPoint): TCalendarPart; override;
    class procedure SetDateTime(const ACalendar: TCustomCalendar; const ADateTime: TDateTime); override;
    class procedure SetDisplaySettings(const ACalendar: TCustomCalendar;
      const ADisplaySettings: TDisplaySettings); override;
    class procedure SetFirstDayOfWeek(const ACalendar: TCustomCalendar;
      const ADayOfWeek: TCalDayOfWeek); override;
    class procedure SetMinMaxDate(const ACalendar: TCustomCalendar;
      AMinDate, AMaxDate: TDateTime); override;
    class procedure RemoveMinMaxDates(const ACalendar: TCustomCalendar); override;
    class procedure GetPreferredSize(const AWinControl: TWinControl;
      var PreferredWidth, PreferredHeight: integer;
      WithThemeSpace: Boolean); override;
  end;


implementation
uses gtk4widgets, gtk4procs;

{ TGtk4WSCustomCalendar }

class function TGtk4WSCustomCalendar.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams
  ): TLCLHandle;
begin
  Result := TLCLHandle(TGtk4Calendar.Create(AWinControl, AParams));
end;

class function TGtk4WSCustomCalendar.GetDateTime(const ACalendar: TCustomCalendar): TDateTime;
var
  Year, Month, Day: LongWord;  //used for csCalendar
begin
  Result := 0;
  if not WSCheckHandleAllocated(ACalendar, 'GetDateTime') then
    Exit;
  TGtk4Calendar(ACalendar.Handle).GetDate(Year, Month, Day);
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSCustomCalendar.GetDateTime: Yr=',dbgs(Year),' Mo=',dbgs(Month),' Dy=',dbgs(Day));
  {$ENDIF}
  { GtkCalendar month is zero-based }
  Result := EncodeDate(Year, Month + 1, Day);
end;

class function TGtk4WSCustomCalendar.HitTest(const ACalendar: TCustomCalendar;
  const APoint: TPoint): TCalendarPart;
{ GTK4: Use gtk4_widget_pick to find the child widget at the test point,
  then walk up the widget tree to identify which part of the calendar
  it belongs to. GtkCalendar internal widget types:
  - GtkButton: navigation buttons in the header -> cpTitleBtn
  - GtkLabel: month/year labels in the header -> cpTitleMonth/cpTitleYear
  - GtkLabel: day-number cells in the grid -> cpDate
  - GtkLabel: week-number labels -> cpWeekNumber
  The header is the first direct child of GtkCalendar. }
var
  CalWidget: PGtkWidget;
  Picked, Walker, HeaderWidget: PGtkWidget;
  DestX, DestY: gdouble;
  TypeName: string;
  Alloc, HeaderAlloc: TGtkAllocation;
  IsInHeader: Boolean;
  ShowWeekNumbers: TGValue;
  HasWeekNums: Boolean;
begin
  Result := cpNoWhere;
  if not WSCheckHandleAllocated(ACalendar, 'HitTest') then
    Exit;

  CalWidget := TGtk4Calendar(ACalendar.Handle).GetContainerWidget;
  if CalWidget = nil then
    Exit;

  { Translate point from LCL coordinates (relative to FWidget=GtkFrame)
    to coordinates relative to the GtkCalendar (FCentralWidget) }
  if not gtk4_widget_translate_coordinates(
    TGtk4Widget(ACalendar.Handle).Widget, CalWidget,
    Double(APoint.X), Double(APoint.Y), @DestX, @DestY) then
    Exit;

  { Pick the widget at the translated point }
  Picked := gtk4_widget_pick(CalWidget, DestX, DestY,
    GTK_PICK_DEFAULT or GTK_PICK_NON_TARGETABLE);
  if (Picked = nil) or (Picked = CalWidget) then
    Exit;

  { Find the header widget (first direct child of the calendar) }
  HeaderWidget := gtk4_widget_get_first_child(CalWidget);

  { Determine if the picked widget is inside the header by walking
    up from the picked widget }
  IsInHeader := False;
  Walker := Picked;
  while (Walker <> nil) and (Walker <> CalWidget) do
  begin
    if Walker = HeaderWidget then
    begin
      IsInHeader := True;
      Break;
    end;
    Walker := Walker^.get_parent;
  end;

  { Identify the picked widget by its GType name }
  TypeName := string(g_type_name_from_instance(PGTypeInstance(Picked)));

  if IsInHeader then
  begin
    { Inside the header area }
    if TypeName = 'GtkButton' then
      Result := cpTitleBtn
    else if TypeName = 'GtkLabel' then
    begin
      { Header label — determine if month or year.
        Month label is on the left side, year on the right. }
      gtk_widget_get_allocation(HeaderWidget, @HeaderAlloc);
      gtk_widget_get_allocation(Picked, @Alloc);
      if Alloc.x + Alloc.width div 2 < HeaderAlloc.width div 2 then
        Result := cpTitleMonth
      else
        Result := cpTitleYear;
    end
    else
      Result := cpTitle;
  end
  else
  begin
    { Below header: day grid area }
    { Query 'show-week-numbers' GObject property }
    HasWeekNums := False;
    FillByte(ShowWeekNumbers{%H-}, SizeOf(ShowWeekNumbers), 0);
    ShowWeekNumbers.init(G_TYPE_BOOLEAN);
    g_object_get_property(PGObject(CalWidget), 'show-week-numbers', @ShowWeekNumbers);
    HasWeekNums := ShowWeekNumbers.get_boolean;
    ShowWeekNumbers.unset;

    if TypeName = 'GtkLabel' then
    begin
      { Day grid labels. Determine if this is a week number or a date cell.
        Week numbers are in column 0 (leftmost). Compare the label's
        X allocation against the first date cell. }
      if HasWeekNums then
      begin
        gtk_widget_get_allocation(Picked, @Alloc);
        gtk_widget_get_allocation(CalWidget, @HeaderAlloc);
        { Week number labels are in the first column. If the label
          starts at X close to 0 relative to the calendar, it's a week number. }
        if Alloc.x < HeaderAlloc.width div 8 then
          Result := cpWeekNumber
        else
          Result := cpDate;
      end
      else
        Result := cpDate;
    end
    else
      Result := cpDate;
  end;
end;

class procedure TGtk4WSCustomCalendar.SetDateTime(const ACalendar: TCustomCalendar; const ADateTime: TDateTime);
var
  Year, Month, Day: Word;
begin
  if not WSCheckHandleAllocated(ACalendar, 'SetDateTime') then
    Exit;
  DecodeDate(ADateTime, Year, Month, Day);
  TGtk4Calendar(ACalendar.Handle).SetDate(Year, Month - 1, Day);
end;

class procedure TGtk4WSCustomCalendar.SetDisplaySettings(const ACalendar: TCustomCalendar;
  const ADisplaySettings: TDisplaySettings);
var
  CalWidget: PGtkWidget;

  procedure SetBoolProperty(const APropName: PGChar; AValue: Boolean);
  var
    Val: TGValue;
  begin
    FillByte(Val{%H-}, SizeOf(Val), 0);
    Val.init(G_TYPE_BOOLEAN);
    Val.set_boolean(AValue);
    g_object_set_property(PGObject(CalWidget), APropName, @Val);
    Val.unset;
  end;

begin
  if not WSCheckHandleAllocated(ACalendar, 'SetDisplaySettings') then
    Exit;

  CalWidget := TGtk4Calendar(ACalendar.Handle).GetContainerWidget;
  if CalWidget = nil then
    Exit;

  { GTK4 GtkCalendar uses GObject boolean properties instead of
    the legacy display-options flags API (which is a no-op in GTK4). }
  SetBoolProperty('show-heading', dsShowHeadings in ADisplaySettings);
  SetBoolProperty('show-day-names', dsShowDayNames in ADisplaySettings);
  SetBoolProperty('show-week-numbers', dsShowWeekNumbers in ADisplaySettings);
end;

class procedure TGtk4WSCustomCalendar.GetPreferredSize(
  const AWinControl: TWinControl; var PreferredWidth, PreferredHeight: integer;
  WithThemeSpace: Boolean);
begin
  if not WSCheckHandleAllocated(AWinControl, 'GetPreferredSize') then Exit;
  TGtk4Widget(AWinControl.Handle).preferredSize(PreferredWidth, PreferredHeight, WithThemeSpace);
end;

class procedure TGtk4WSCustomCalendar.SetFirstDayOfWeek(
  const ACalendar: TCustomCalendar; const ADayOfWeek: TCalDayOfWeek);
begin
  { GtkCalendar uses locale-based first day of week, no native API to override }
  if not WSCheckHandleAllocated(ACalendar, 'SetFirstDayOfWeek') then Exit;
end;

class procedure TGtk4WSCustomCalendar.SetMinMaxDate(
  const ACalendar: TCustomCalendar; AMinDate, AMaxDate: TDateTime);
begin
  if not WSCheckHandleAllocated(ACalendar, 'SetMinMaxDate') then Exit;
  TGtk4Calendar(ACalendar.Handle).SetMinMaxDate(AMinDate, AMaxDate);
end;

class procedure TGtk4WSCustomCalendar.RemoveMinMaxDates(
  const ACalendar: TCustomCalendar);
begin
  if not WSCheckHandleAllocated(ACalendar, 'RemoveMinMaxDates') then Exit;
  TGtk4Calendar(ACalendar.Handle).RemoveMinMaxDates;
end;

end.
