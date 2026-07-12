{
 *****************************************************************************
 *                               gtk4themes.pas                              *
 *                               --------------                              *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit gtk4themes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Math,
  // LCL
  LCLType, LCLProc, Themes, TmSchema,
  // GTK4
  LazGtk4, LazGlib2, LazCairo1,
  gtk4objects, gtk4procs;

type

  { TGtk4ThemeServices }

  TGtk4ThemeServices = class(TThemeServices)
  private
    function GetGtkStateFlags(Details: TThemedElementDetails): TGtkStateFlags;
  protected
    function InitThemes: Boolean; override;
    function UseThemes: Boolean; override;
    function ThemedControlsEnabled: Boolean; override;
  public
    procedure DrawElement(DC: HDC; Details: TThemedElementDetails;
      const R: TRect; ClipRect: PRect = nil); override;
    function GetDetailSizeForPPI(Details: TThemedElementDetails;
      PPI: Integer): TSize; override;
    function ContentRect(DC: HDC; Details: TThemedElementDetails;
      BoundingRect: TRect): TRect; override;
    function HasTransparentParts(Details: TThemedElementDetails): Boolean; override;
    function GetOption(AOption: TThemeOption): Integer; override;
  end;

implementation

{ TGtk4ThemeServices }

function TGtk4ThemeServices.InitThemes: Boolean;
begin
  Result := True;
end;

function TGtk4ThemeServices.UseThemes: Boolean;
begin
  Result := True;
end;

function TGtk4ThemeServices.ThemedControlsEnabled: Boolean;
begin
  Result := True;
end;

function TGtk4ThemeServices.GetGtkStateFlags(
  Details: TThemedElementDetails): TGtkStateFlags;
begin
  Result := [];
  case Details.Element of
    teButton:
      case Details.Part of
        BP_PUSHBUTTON:
          case Details.State of
            PBS_HOT: Include(Result, GTK_STATE_FLAG_PRELIGHT);
            PBS_PRESSED: Include(Result, GTK_STATE_FLAG_ACTIVE);
            PBS_DISABLED: Include(Result, GTK_STATE_FLAG_INSENSITIVE);
          end;
        BP_RADIOBUTTON:
          begin
            case Details.State of
              RBS_UNCHECKEDHOT, RBS_CHECKEDHOT:
                Include(Result, GTK_STATE_FLAG_PRELIGHT);
              RBS_UNCHECKEDPRESSED, RBS_CHECKEDPRESSED:
                Include(Result, GTK_STATE_FLAG_ACTIVE);
              RBS_UNCHECKEDDISABLED, RBS_CHECKEDDISABLED:
                Include(Result, GTK_STATE_FLAG_INSENSITIVE);
            end;
            if Details.State >= RBS_CHECKEDNORMAL then
              Include(Result, GTK_STATE_FLAG_CHECKED);
          end;
        BP_CHECKBOX:
          begin
            case Details.State of
              CBS_UNCHECKEDHOT, CBS_CHECKEDHOT, CBS_MIXEDHOT:
                Include(Result, GTK_STATE_FLAG_PRELIGHT);
              CBS_UNCHECKEDPRESSED, CBS_CHECKEDPRESSED, CBS_MIXEDPRESSED:
                Include(Result, GTK_STATE_FLAG_ACTIVE);
              CBS_UNCHECKEDDISABLED, CBS_CHECKEDDISABLED, CBS_MIXEDDISABLED:
                Include(Result, GTK_STATE_FLAG_INSENSITIVE);
            end;
            if (Details.State >= CBS_CHECKEDNORMAL) and
               (Details.State <= CBS_CHECKEDDISABLED) then
              Include(Result, GTK_STATE_FLAG_CHECKED)
            else if Details.State >= CBS_MIXEDNORMAL then
              Include(Result, GTK_STATE_FLAG_INCONSISTENT);
          end;
      end;
    teTreeView:
      case Details.Part of
        TVP_GLYPH, TVP_HOTGLYPH:
          begin
            if Details.Part = TVP_HOTGLYPH then
              Include(Result, GTK_STATE_FLAG_PRELIGHT);
            if Details.State <> GLPS_CLOSED then
              Include(Result, GTK_STATE_FLAG_CHECKED);
          end;
        TVP_TREEITEM:
          case Details.State of
            TREIS_HOT:
              Include(Result, GTK_STATE_FLAG_PRELIGHT);
            TREIS_SELECTED:
              begin
                Include(Result, GTK_STATE_FLAG_SELECTED);
                Include(Result, GTK_STATE_FLAG_FOCUSED);
              end;
            TREIS_DISABLED:
              Include(Result, GTK_STATE_FLAG_INSENSITIVE);
            TREIS_SELECTEDNOTFOCUS:
              Include(Result, GTK_STATE_FLAG_SELECTED);
            TREIS_HOTSELECTED:
              begin
                Include(Result, GTK_STATE_FLAG_SELECTED);
                Include(Result, GTK_STATE_FLAG_PRELIGHT);
              end;
          end;
      end;
    teToolBar:
      begin
        if IsPushed(Details) or IsChecked(Details) then
          Include(Result, GTK_STATE_FLAG_ACTIVE)
        else if IsHot(Details) then
          Include(Result, GTK_STATE_FLAG_PRELIGHT);
        if IsDisabled(Details) then
          Include(Result, GTK_STATE_FLAG_INSENSITIVE);
      end;
    teHeader:
      begin
        if IsPushed(Details) then
          Include(Result, GTK_STATE_FLAG_ACTIVE)
        else if IsHot(Details) then
          Include(Result, GTK_STATE_FLAG_PRELIGHT);
      end;
  end;
end;

procedure TGtk4ThemeServices.DrawElement(DC: HDC;
  Details: TThemedElementDetails; const R: TRect; ClipRect: PRect);
var
  DevCtx: TGtk4DeviceContext;
  pcr: Pcairo_t;
  w: PGtkWidget;
  Context: PGtkStyleContext;
  StateFlags: TGtkStateFlags;
  ARect: TRect;
  x, y, dw, dh: Double;
  ArrowAngle: Double;
begin
  if (DC = 0) or not (TObject(DC) is TGtk4DeviceContext) then
  begin
    inherited;
    exit;
  end;

  DevCtx := TGtk4DeviceContext(DC);
  pcr := DevCtx.pcr;
  if pcr = nil then
  begin
    inherited;
    exit;
  end;

  ARect := R;
  x := ARect.Left;
  y := ARect.Top;
  dw := ARect.Right - ARect.Left;
  dh := ARect.Bottom - ARect.Top;
  StateFlags := GetGtkStateFlags(Details);

  case Details.Element of
    teTreeView:
      case Details.Part of
        TVP_GLYPH, TVP_HOTGLYPH:
          begin
            w := GetStyleWidget(lgsTreeView);
            if w = nil then begin inherited; exit; end;
            Context := w^.get_style_context;
            gtk_style_context_save(Context);
            gtk_style_context_add_class(Context, 'expander');
            gtk_style_context_set_state(Context, StateFlags);
            gtk_render_expander(Context, pcr, x, y, dw, dh);
            gtk_style_context_restore(Context);
          end;
        TVP_TREEITEM:
          begin
            w := GetStyleWidget(lgsTreeView);
            if w = nil then begin inherited; exit; end;
            Context := w^.get_style_context;
            gtk_style_context_save(Context);
            gtk_style_context_set_state(Context, StateFlags);
            gtk_render_background(Context, pcr, x, y, dw, dh);
            if Details.State in [TREIS_SELECTED, TREIS_HOTSELECTED,
                                 TREIS_SELECTEDNOTFOCUS] then
              gtk_render_focus(Context, pcr, x, y, dw, dh);
            gtk_style_context_restore(Context);
          end;
      else
        inherited;
      end;

    teButton:
      case Details.Part of
        BP_CHECKBOX:
          begin
            w := GetStyleWidget(lgsCheckbox);
            if w = nil then begin inherited; exit; end;
            Context := w^.get_style_context;
            gtk_style_context_save(Context);
            gtk_style_context_set_state(Context, StateFlags);
            gtk_render_background(Context, pcr, x, y, dw, dh);
            gtk_render_check(Context, pcr, x, y, dw, dh);
            gtk_style_context_restore(Context);
          end;
        BP_RADIOBUTTON:
          begin
            w := GetStyleWidget(lgsRadiobutton);
            if w = nil then begin inherited; exit; end;
            Context := w^.get_style_context;
            gtk_style_context_save(Context);
            gtk_style_context_set_state(Context, StateFlags);
            gtk_render_background(Context, pcr, x, y, dw, dh);
            gtk_render_option(Context, pcr, x, y, dw, dh);
            gtk_style_context_restore(Context);
          end;
        BP_PUSHBUTTON:
          begin
            w := GetStyleWidget(lgsButton);
            if w = nil then begin inherited; exit; end;
            Context := w^.get_style_context;
            gtk_style_context_save(Context);
            gtk_style_context_set_state(Context, StateFlags);
            gtk_render_background(Context, pcr, x, y, dw, dh);
            gtk_render_frame(Context, pcr, x, y, dw, dh);
            gtk_style_context_restore(Context);
          end;
      else
        inherited;
      end;

    teToolBar:
      case Details.Part of
        TP_BUTTON, TP_SPLITBUTTON:
          begin
            w := GetStyleWidget(lgsToolButton);
            if w = nil then
              w := GetStyleWidget(lgsButton);
            if w = nil then begin inherited; exit; end;
            Context := w^.get_style_context;
            gtk_style_context_save(Context);
            gtk_style_context_set_state(Context, StateFlags);
            if IsPushed(Details) or IsHot(Details) or IsChecked(Details) then
            begin
              gtk_render_background(Context, pcr, x, y, dw, dh);
              gtk_render_frame(Context, pcr, x, y, dw, dh);
            end;
            gtk_style_context_restore(Context);
          end;
        TP_DROPDOWNBUTTON, TP_SPLITBUTTONDROPDOWN:
          begin
            w := GetStyleWidget(lgsToolButton);
            if w = nil then
              w := GetStyleWidget(lgsButton);
            if w = nil then begin inherited; exit; end;
            Context := w^.get_style_context;
            gtk_style_context_save(Context);
            gtk_style_context_set_state(Context, StateFlags);
            if IsPushed(Details) or IsHot(Details) then
            begin
              gtk_render_background(Context, pcr, x, y, dw, dh);
              gtk_render_frame(Context, pcr, x, y, dw, dh);
            end;
            { draw dropdown arrow }
            ArrowAngle := Pi; { down }
            gtk_render_arrow(Context, pcr, ArrowAngle,
              x + (dw - dh) / 2, y, dh);
            gtk_style_context_restore(Context);
          end;
        TP_SEPARATOR:
          begin
            w := GetStyleWidget(lgsToolBar);
            if w = nil then begin inherited; exit; end;
            Context := w^.get_style_context;
            gtk_style_context_save(Context);
            gtk_style_context_set_state(Context, StateFlags);
            gtk_render_line(Context, pcr,
              x + dw / 2, y + 2, x + dw / 2, y + dh - 2);
            gtk_style_context_restore(Context);
          end;
        TP_SEPARATORVERT:
          begin
            w := GetStyleWidget(lgsToolBar);
            if w = nil then begin inherited; exit; end;
            Context := w^.get_style_context;
            gtk_style_context_save(Context);
            gtk_style_context_set_state(Context, StateFlags);
            gtk_render_line(Context, pcr,
              x + 2, y + dh / 2, x + dw - 2, y + dh / 2);
            gtk_style_context_restore(Context);
          end;
      else
        inherited;
      end;

    teHeader:
      case Details.Part of
        HP_HEADERITEM, HP_HEADERITEMLEFT, HP_HEADERITEMRIGHT:
          begin
            w := GetStyleWidget(lgsButton);
            if w = nil then begin inherited; exit; end;
            Context := w^.get_style_context;
            gtk_style_context_save(Context);
            gtk_style_context_set_state(Context, StateFlags);
            gtk_render_background(Context, pcr, x, y, dw, dh);
            gtk_render_frame(Context, pcr, x, y, dw, dh);
            gtk_style_context_restore(Context);
          end;
        HP_HEADERSORTARROW:
          begin
            w := GetStyleWidget(lgsTreeView);
            if w = nil then begin inherited; exit; end;
            Context := w^.get_style_context;
            gtk_style_context_save(Context);
            gtk_style_context_set_state(Context, StateFlags);
            if Details.State = HSAS_SORTEDDOWN then
              ArrowAngle := Pi    { down }
            else
              ArrowAngle := 0;    { up }
            gtk_render_arrow(Context, pcr, ArrowAngle, x, y,
              Min(dw, dh));
            gtk_style_context_restore(Context);
          end;
      else
        inherited;
      end;

    teWindow:
      case Details.Part of
        WP_MINBUTTON, WP_MDIMINBUTTON,
        WP_MAXBUTTON, WP_CLOSEBUTTON, WP_SMALLCLOSEBUTTON,
        WP_MDICLOSEBUTTON, WP_RESTOREBUTTON, WP_MDIRESTOREBUTTON,
        WP_HELPBUTTON, WP_MDIHELPBUTTON:
          inherited;
      else
        inherited;
      end;

    teTab:
      case Details.Part of
        TABP_PANE, TABP_BODY:
          begin
            w := GetStyleWidget(lgsNotebook);
            if w = nil then begin inherited; exit; end;
            Context := w^.get_style_context;
            gtk_style_context_save(Context);
            gtk_style_context_set_state(Context, StateFlags);
            gtk_render_background(Context, pcr, x, y, dw, dh);
            gtk_render_frame(Context, pcr, x, y, dw, dh);
            gtk_style_context_restore(Context);
          end;
      else
        inherited;
      end;

    teToolTip:
      if Details.Part = TTP_STANDARD then
      begin
        w := GetStyleWidget(lgsTooltip);
        if w = nil then begin inherited; exit; end;
        Context := w^.get_style_context;
        gtk_style_context_save(Context);
        gtk_style_context_set_state(Context, StateFlags);
        gtk_render_background(Context, pcr, x, y, dw, dh);
        gtk_render_frame(Context, pcr, x, y, dw, dh);
        gtk_style_context_restore(Context);
      end
      else
        inherited;

  else
    inherited;
  end;
end;

function TGtk4ThemeServices.GetDetailSizeForPPI(
  Details: TThemedElementDetails; PPI: Integer): TSize;
begin
  case Details.Element of
    teTreeView:
      if Details.Part in [TVP_GLYPH, TVP_HOTGLYPH] then
      begin
        Result := Size(16, 16);
        Result.cx := MulDiv(Result.cx, PPI, 96);
        Result.cy := MulDiv(Result.cy, PPI, 96);
      end
      else
        Result := inherited;
    teButton:
      if Details.Part in [BP_CHECKBOX, BP_RADIOBUTTON] then
      begin
        Result := Size(14, 14);
        Result.cx := MulDiv(Result.cx, PPI, 96);
        Result.cy := MulDiv(Result.cy, PPI, 96);
      end
      else
        Result := inherited;
    teToolBar:
      if Details.Part in [TP_SPLITBUTTONDROPDOWN, TP_DROPDOWNBUTTON] then
      begin
        Result.cx := MulDiv(12, PPI, 96);
        Result.cy := -1;
      end
      else
        Result := inherited;
  else
    Result := inherited;
  end;
end;

function TGtk4ThemeServices.ContentRect(DC: HDC;
  Details: TThemedElementDetails; BoundingRect: TRect): TRect;
begin
  Result := BoundingRect;
  case Details.Element of
    teButton:
      if Details.Part = BP_PUSHBUTTON then
        InflateRect(Result, -2, -2);
    teToolBar:
      if Details.Part in [TP_BUTTON, TP_SPLITBUTTON] then
        InflateRect(Result, -1, -1);
  else
    Result := inherited;
  end;
end;

function TGtk4ThemeServices.HasTransparentParts(
  Details: TThemedElementDetails): Boolean;
begin
  Result := True;
end;

function TGtk4ThemeServices.GetOption(AOption: TThemeOption): Integer;
begin
  case AOption of
    toShowButtonImages: Result := 1;
    toShowMenuImages: Result := 1;
  else
    Result := inherited;
  end;
end;

end.
