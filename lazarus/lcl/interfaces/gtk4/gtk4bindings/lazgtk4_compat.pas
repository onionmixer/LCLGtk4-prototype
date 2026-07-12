{ GTK4 Compatibility Binding Unit
  Declares GTK4-specific functions not present in the GTK3-derived lazgtk4.pas.
  Uses 'name' clause to map Pascal identifiers to actual C symbol names.
  Only functions that changed signature or are new in GTK4 are declared here. }
unit LazGtk4_Compat;

{$MODE OBJFPC}{$H+}
{$PACKRECORDS C}

interface

uses
  CTypes, LazGLib2, LazGObject2, LazGio2, LazGtk4, LazGdk4, LazGdkPixbuf2,
  LazCairo1, LazGsk4;

const
  {$ifdef MsWindows}
  LazGtk4C_library = 'libgtk-4-1.dll';
  {$else}
  LazGtk4C_library = 'libgtk-4.so.1';
  {$endif}

  { GTK4 native GdkEventType values.
    The lazgdk4.pas binding has GTK3 enum values (GDK_BUTTON_PRESS=4, etc.)
    but GTK4 renumbered the enum starting from 0. These constants reflect the
    actual C enum values returned by gdk_event_get_event_type() in GTK4.
    Use these when matching native event types from GTK4 API calls.
    Use the lazgdk4.pas constants (GDK_BUTTON_PRESS etc.) for synthetic events. }
  GDK4_DELETE          = 0;
  GDK4_MOTION_NOTIFY   = 1;
  GDK4_BUTTON_PRESS    = 2;
  GDK4_BUTTON_RELEASE  = 3;
  GDK4_KEY_PRESS       = 4;
  GDK4_KEY_RELEASE     = 5;
  GDK4_ENTER_NOTIFY    = 6;
  GDK4_LEAVE_NOTIFY    = 7;
  GDK4_FOCUS_CHANGE    = 8;
  GDK4_SCROLL          = 9;
  GDK4_GRAB_BROKEN     = 10;

type
  { GtkDrawingAreaDrawFunc callback type (new in GTK4) }
  TGtkDrawingAreaDrawFunc = procedure(drawing_area: PGtkDrawingArea;
    cr: Pcairo_t; width: gint; height: gint; user_data: gpointer); cdecl;

  { GtkGestureClick - renamed from GtkGestureMultiPress in GTK4 }
  PGtkGestureClick = ^TGtkGestureClick;
  TGtkGestureClick = object(TGtkGestureSingle)
  end;

  { GtkEventControllerFocus - new in GTK4 (focus was part of GtkEventControllerKey in GTK3) }
  PGtkEventControllerFocus = ^TGtkEventControllerFocus;
  TGtkEventControllerFocus = object(TGtkEventController)
  end;

  { Graphene types used by gtk_widget_compute_bounds }
  graphene_point_t = record x, y: gfloat; end;
  graphene_size_t = record width, height: gfloat; end;
  Pgraphene_rect_t = ^graphene_rect_t;
  graphene_rect_t = record origin: graphene_point_t; size: graphene_size_t; end;

{ ---- Initialization ---- }

{ GTK4: gtk_init() takes no arguments }
procedure gtk4_init; cdecl;
  external LazGtk4C_library name 'gtk_init';

{ ---- Window ---- }

{ GTK4: gtk_window_new() takes no type argument, always creates toplevel }
function gtk4_window_new: PGtkWidget; cdecl;
  external LazGtk4C_library name 'gtk_window_new';

{ GTK4: replaces gtk_container_add for windows }
procedure gtk4_window_set_child(window: PGtkWindow; child: PGtkWidget); cdecl;
  external LazGtk4C_library name 'gtk_window_set_child';

{ GTK4: replaces gtk_window_iconify }
procedure gtk4_window_minimize(window: PGtkWindow); cdecl;
  external LazGtk4C_library name 'gtk_window_minimize';

{ GTK4: gtk_window_destroy is the correct way to destroy a toplevel window.
  gtk_widget_destroy was removed; gtk_widget_unparent does not work on toplevels. }
procedure gtk4_window_destroy(window: PGtkWindow); cdecl;
  external LazGtk4C_library name 'gtk_window_destroy';

{ ---- Box (replaces pack_start/pack_end) ---- }

procedure gtk4_box_append(box: PGtkBox; child: PGtkWidget); cdecl;
  external LazGtk4C_library name 'gtk_box_append';

procedure gtk4_box_prepend(box: PGtkBox; child: PGtkWidget); cdecl;
  external LazGtk4C_library name 'gtk_box_prepend';

procedure gtk4_box_remove(box: PGtkBox; child: PGtkWidget); cdecl;
  external LazGtk4C_library name 'gtk_box_remove';

{ ---- ScrolledWindow (no-arg constructor, set_child replaces add) ---- }

function gtk4_scrolled_window_new: PGtkWidget; cdecl;
  external LazGtk4C_library name 'gtk_scrolled_window_new';

procedure gtk4_scrolled_window_set_child(sw: PGtkScrolledWindow; child: PGtkWidget); cdecl;
  external LazGtk4C_library name 'gtk_scrolled_window_set_child';

{ ---- Fixed (double coordinates in GTK4, was gint in GTK3) ---- }

procedure gtk4_fixed_put(fixed: PGtkFixed; widget: PGtkWidget; x: double; y: double); cdecl;
  external LazGtk4C_library name 'gtk_fixed_put';

procedure gtk4_fixed_move(fixed: PGtkFixed; widget: PGtkWidget; x: double; y: double); cdecl;
  external LazGtk4C_library name 'gtk_fixed_move';

procedure gtk4_fixed_remove(fixed: PGtkFixed; widget: PGtkWidget); cdecl;
  external LazGtk4C_library name 'gtk_fixed_remove';

{ ---- Widget controller API ---- }

procedure gtk4_widget_add_controller(widget: PGtkWidget; controller: PGtkEventController); cdecl;
  external LazGtk4C_library name 'gtk_widget_add_controller';

procedure gtk4_widget_remove_controller(widget: PGtkWidget; controller: PGtkEventController); cdecl;
  external LazGtk4C_library name 'gtk_widget_remove_controller';

{ ---- Event controllers (no-arg constructors in GTK4, took widget in GTK3) ---- }

function gtk4_gesture_click_new: PGtkGesture; cdecl;
  external LazGtk4C_library name 'gtk_gesture_click_new';

function gtk4_event_controller_key_new: PGtkEventController; cdecl;
  external LazGtk4C_library name 'gtk_event_controller_key_new';

function gtk4_event_controller_motion_new: PGtkEventController; cdecl;
  external LazGtk4C_library name 'gtk_event_controller_motion_new';

function gtk4_event_controller_focus_new: PGtkEventController; cdecl;
  external LazGtk4C_library name 'gtk_event_controller_focus_new';

function gtk4_event_controller_scroll_new(flags: TGtkEventControllerScrollFlags): PGtkEventController; cdecl;
  external LazGtk4C_library name 'gtk_event_controller_scroll_new';

function gtk4_event_controller_legacy_new: PGtkEventController; cdecl;
  external LazGtk4C_library name 'gtk_event_controller_legacy_new';

{ ---- Gesture constructors (GTK4 no-arg, signals deliver data) ---- }

{ GtkGestureDrag: tracks drag offset from press point.
  Signals: 'drag-begin(start_x, start_y)', 'drag-update(offset_x, offset_y)', 'drag-end(offset_x, offset_y)' }
function gtk4_gesture_drag_new: PGtkGesture; cdecl;
  external LazGtk4C_library name 'gtk_gesture_drag_new';

{ GtkGestureLongPress: fires after long press (timeout).
  Signals: 'pressed(x, y)', 'cancelled' }
function gtk4_gesture_long_press_new: PGtkGesture; cdecl;
  external LazGtk4C_library name 'gtk_gesture_long_press_new';

{ GtkGestureSwipe: detects swipe direction/velocity.
  Signal: 'swipe(velocity_x, velocity_y)' }
function gtk4_gesture_swipe_new: PGtkGesture; cdecl;
  external LazGtk4C_library name 'gtk_gesture_swipe_new';

{ GtkGestureRotate: two-finger rotation (multitouch).
  Signal: 'angle-changed(angle, angle_delta)' }
function gtk4_gesture_rotate_new: PGtkGesture; cdecl;
  external LazGtk4C_library name 'gtk_gesture_rotate_new';

{ GtkGestureZoom: two-finger pinch/zoom (multitouch).
  Signal: 'scale-changed(scale)' }
function gtk4_gesture_zoom_new: PGtkGesture; cdecl;
  external LazGtk4C_library name 'gtk_gesture_zoom_new';

{ GtkGestureStylus: tablet pen input.
  Signals: 'proximity(x, y)', 'down(x, y)', 'motion(x, y)', 'up(x, y)' }
function gtk4_gesture_stylus_new: PGtkGesture; cdecl;
  external LazGtk4C_library name 'gtk_gesture_stylus_new';

{ GtkGestureDrag helpers: get start point and offset }
function gtk4_gesture_drag_get_start_point(gesture: PGtkGesture;
  x: Pgdouble; y: Pgdouble): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_gesture_drag_get_start_point';

function gtk4_gesture_drag_get_offset(gesture: PGtkGesture;
  x: Pgdouble; y: Pgdouble): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_gesture_drag_get_offset';

{ GtkGestureSwipe helper: get velocity }
function gtk4_gesture_swipe_get_velocity(gesture: PGtkGesture;
  velocity_x: Pgdouble; velocity_y: Pgdouble): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_gesture_swipe_get_velocity';

{ GtkGestureRotate helper: get rotation angle }
function gtk4_gesture_rotate_get_angle_delta(gesture: PGtkGesture): gdouble; cdecl;
  external LazGtk4C_library name 'gtk_gesture_rotate_get_angle_delta';

{ GtkGestureZoom helper: get zoom scale factor }
function gtk4_gesture_zoom_get_scale_delta(gesture: PGtkGesture): gdouble; cdecl;
  external LazGtk4C_library name 'gtk_gesture_zoom_get_scale_delta';

{ GtkGesture base: set exclusive/touchonly }
procedure gtk4_gesture_single_set_exclusive(gesture: PGtkGestureSingle;
  exclusive: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_gesture_single_set_exclusive';

procedure gtk4_gesture_single_set_touch_only(gesture: PGtkGestureSingle;
  touch_only: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_gesture_single_set_touch_only';

procedure gtk4_gesture_single_set_button(gesture: PGtkGestureSingle;
  button: guint); cdecl;
  external LazGtk4C_library name 'gtk_gesture_single_set_button';

{ ---- Drawing area (new draw_func API in GTK4, replaces 'draw' signal) ---- }

procedure gtk4_drawing_area_set_draw_func(area: PGtkDrawingArea;
  draw_func: TGtkDrawingAreaDrawFunc; user_data: gpointer;
  destroy_notify: TGDestroyNotify); cdecl;
  external LazGtk4C_library name 'gtk_drawing_area_set_draw_func';

{ ---- CSS provider (changed signatures in GTK4) ---- }

{ GTK4: 2-param version (no GError parameter) }
procedure gtk4_css_provider_load_from_path(provider: PGtkCssProvider; path: Pgchar); cdecl;
  external LazGtk4C_library name 'gtk_css_provider_load_from_path';

{ GTK4: uses display instead of screen }
procedure gtk4_style_context_add_provider_for_display(display: PGdkDisplay;
  provider: PGtkStyleProvider; priority: guint); cdecl;
  external LazGtk4C_library name 'gtk_style_context_add_provider_for_display';

{ ---- GDK display ---- }

function gdk4_display_get_default: PGdkDisplay; cdecl;
  external LazGtk4C_library name 'gdk_display_get_default';

{ ---- Frame (set_child replaces container add) ---- }

procedure gtk4_frame_set_child(frame: PGtkFrame; child: PGtkWidget); cdecl;
  external LazGtk4C_library name 'gtk_frame_set_child';

{ ---- Overlay (set_child is new in GTK4, replaces container_add) ---- }

function gtk4_overlay_new: PGtkWidget; cdecl;
  external LazGtk4C_library name 'gtk_overlay_new';

procedure gtk4_overlay_set_child(overlay: PGtkOverlay; child: PGtkWidget); cdecl;
  external LazGtk4C_library name 'gtk_overlay_set_child';

{ ---- DrawingArea (set_content_width/height for sizing) ---- }

procedure gtk4_drawing_area_set_content_width(area: PGtkDrawingArea; width: gint); cdecl;
  external LazGtk4C_library name 'gtk_drawing_area_set_content_width';

procedure gtk4_drawing_area_set_content_height(area: PGtkDrawingArea; height: gint); cdecl;
  external LazGtk4C_library name 'gtk_drawing_area_set_content_height';

{ ---- Widget (set_can_target controls whether widget receives input events) ---- }

procedure gtk4_widget_set_can_target(widget: PGtkWidget; can_target: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_widget_set_can_target';

{ ---- Widget overflow (GTK4: controls child clipping behaviour) ---- }
{ GTK_OVERFLOW_VISIBLE = 0: children may extend beyond the widget bounds.
  GTK_OVERFLOW_HIDDEN = 1 (default): children clipped to widget allocation. }
const
  GTK4_OVERFLOW_VISIBLE = 0;
  GTK4_OVERFLOW_HIDDEN  = 1;

procedure gtk4_widget_set_overflow(widget: PGtkWidget; overflow: gint); cdecl;
  external LazGtk4C_library name 'gtk_widget_set_overflow';
function gtk4_widget_get_overflow(widget: PGtkWidget): gint; cdecl;
  external LazGtk4C_library name 'gtk_widget_get_overflow';

{ Widget - CSS class manipulation (GTK 4.0+) }
procedure gtk4_widget_add_css_class(widget: PGtkWidget; css_class: PgChar); cdecl;
  external LazGtk4C_library name 'gtk_widget_add_css_class';
procedure gtk4_widget_remove_css_class(widget: PGtkWidget; css_class: PgChar); cdecl;
  external LazGtk4C_library name 'gtk_widget_remove_css_class';

{ ---- GestureClick (get current button) ---- }

function gtk4_gesture_single_get_current_button(gesture: PGtkGestureSingle): guint; cdecl;
  external LazGtk4C_library name 'gtk_gesture_single_get_current_button';

{ ---- EventController (get modifier state during callback) ---- }

function gtk4_event_controller_get_current_event_state(controller: PGtkEventController): TGdkModifierType; cdecl;
  external LazGtk4C_library name 'gtk_event_controller_get_current_event_state';

function gtk4_event_controller_get_current_event(controller: PGtkEventController): PGdkEvent; cdecl;
  external LazGtk4C_library name 'gtk_event_controller_get_current_event';

{ ---- GDK4 opaque event accessors (new in GTK4) ---- }

function gdk4_event_get_position(event: PGdkEvent; out x: double; out y: double): gboolean; cdecl;
  external LazGtk4C_library name 'gdk_event_get_position';

function gdk4_button_event_get_button(event: PGdkEvent): guint; cdecl;
  external LazGtk4C_library name 'gdk_button_event_get_button';

function gdk4_event_get_modifier_state(event: PGdkEvent): TGdkModifierType; cdecl;
  external LazGtk4C_library name 'gdk_event_get_modifier_state';

{ ---- Widget size allocation (GTK4 added baseline parameter) ---- }

{ GTK4: gtk_widget_size_allocate now takes 3 params (widget, allocation, baseline).
  The GTK3 binding only has 2 params, causing garbage baseline values.
  Use baseline=-1 for "no baseline". }
procedure gtk4_widget_size_allocate(widget: PGtkWidget; allocation: PGtkAllocation; baseline: gint); cdecl;
  external LazGtk4C_library name 'gtk_widget_size_allocate';

{ ---- Widget visual bounds (GTK4: measure CSS overflow like box-shadow) ---- }

{ gtk_widget_compute_bounds returns the full visual bounds including CSS effects
  (box-shadow, etc.) relative to target widget. Returns FALSE if widget not realized. }
function gtk4_widget_compute_bounds(widget: PGtkWidget; target: PGtkWidget;
  out_bounds: Pgraphene_rect_t): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_widget_compute_bounds';

{ ---- GtkEditable (GTK4: replaces GtkEntry get_text/set_text) ---- }

{ GTK4: gtk_entry_get_text/set_text removed. Use GtkEditable interface instead. }
function gtk4_editable_get_text(editable: PGtkWidget): Pgchar; cdecl;
  external LazGtk4C_library name 'gtk_editable_get_text';

procedure gtk4_editable_set_text(editable: PGtkWidget; text: Pgchar); cdecl;
  external LazGtk4C_library name 'gtk_editable_set_text';

{ ---- GtkCheckButton (GTK4: no longer subclass of GtkButton) ---- }

{ GTK4: GtkCheckButton is now derived from GtkWidget, not GtkToggleButton/GtkButton.
  It has its own label/underline API instead of inheriting from GtkButton. }
procedure gtk4_check_button_set_label(button: PGtkCheckButton; label_: Pgchar); cdecl;
  external LazGtk4C_library name 'gtk_check_button_set_label';

function gtk4_check_button_get_label(button: PGtkCheckButton): Pgchar; cdecl;
  external LazGtk4C_library name 'gtk_check_button_get_label';

procedure gtk4_check_button_set_use_underline(button: PGtkCheckButton; setting: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_check_button_set_use_underline';

{ GTK4 radio grouping: GtkRadioButton is gone; check buttons form a radio
  group by sharing a group member. (The legacy TGtkRadioButton.join_group
  helper in lazgtk4.pas is an empty stub — do not use it.) }
procedure gtk4_check_button_set_group(button: PGtkCheckButton; group: PGtkCheckButton); cdecl;
  external LazGtk4C_library name 'gtk_check_button_set_group';

{ GTK4 calendar date API. GTK4 changed both signatures to GDateTime:
  gtk_calendar_select_day(cal, GDateTime*) and
  gtk_calendar_get_date(cal): GDateTime*. The legacy TGtkCalendar helpers
  in lazgtk4.pas keep the GTK3 shapes: select_day(guint) passes an
  integer where a GDateTime pointer is expected (access violation on
  every call) and get_date(y,m,d out-params) never writes its outputs. }
procedure gtk4_calendar_select_day(calendar: PGtkCalendar; date: PGDateTime); cdecl;
  external LazGtk4C_library name 'gtk_calendar_select_day';
function gtk4_calendar_get_date(calendar: PGtkCalendar): PGDateTime; cdecl;
  external LazGtk4C_library name 'gtk_calendar_get_date';

{ GTK4 paned slot getters. The legacy TGtkPaned.get_child1/get_child2
  helpers in lazgtk4.pas are constant-nil stubs — do not use them. }
function gtk4_paned_get_start_child(paned: PGtkPaned): PGtkWidget; cdecl;
  external LazGtk4C_library name 'gtk_paned_get_start_child';
function gtk4_paned_get_end_child(paned: PGtkPaned): PGtkWidget; cdecl;
  external LazGtk4C_library name 'gtk_paned_get_end_child';

procedure gtk4_check_button_set_active(button: PGtkCheckButton; setting: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_check_button_set_active';

function gtk4_check_button_get_active(button: PGtkCheckButton): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_check_button_get_active';

procedure gtk4_check_button_set_inconsistent(button: PGtkCheckButton; inconsistent: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_check_button_set_inconsistent';

function gtk4_check_button_get_inconsistent(button: PGtkCheckButton): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_check_button_get_inconsistent';

{ ---- GdkDevice modifier state (GTK4: replaces GdkKeymap.get_modifier_state) ---- }

{ GTK4: GdkKeymap was removed. Query modifier state from the keyboard GdkDevice instead. }
function gtk4_device_get_modifier_state(device: PGdkDevice): TGdkModifierType; cdecl;
  external LazGdk4_library name 'gdk_device_get_modifier_state';

{ ---- Display monitors (GTK4: replaces gdk_screen_get_width/height) ---- }

{ GTK4: GdkScreen was removed. Use GdkDisplay monitors list instead. }
function gtk4_display_get_monitors(display: PGdkDisplay): PGListModel; cdecl;
  external LazGdk4_library name 'gdk_display_get_monitors';

{ ---- Widget pick (GTK4-only: hit testing) ---- }

{ GtkPickFlags for gtk_widget_pick }
const
  GTK_PICK_DEFAULT = 0;
  GTK_PICK_INSENSITIVE = 1;
  GTK_PICK_NON_TARGETABLE = 2;

{ GTK4: gtk_widget_pick returns the widget at the given coordinates }
function gtk4_widget_pick(widget: PGtkWidget; x: double; y: double;
  flags: guint): PGtkWidget; cdecl;
  external LazGtk4C_library name 'gtk_widget_pick';

{ GTK4: gtk_widget_translate_coordinates changed signature from gint to double.
  The lazgtk4.pas binding uses gint (GTK3 signature) which causes ABI mismatch
  on x86_64 (integers in GPR vs doubles in XMM). This version uses the correct
  GTK4 double signature. }
function gtk4_widget_translate_coordinates(src_widget: PGtkWidget;
  dest_widget: PGtkWidget; src_x: double; src_y: double;
  dest_x: Pgdouble; dest_y: Pgdouble): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_widget_translate_coordinates';

{ ---- Widget native/root (GTK4: for coordinate translation) ---- }

{ GTK4: Returns the GtkNative that contains this widget (typically the GtkWindow).
  The returned pointer is a GtkNative interface but can be cast to PGtkWidget
  since GtkWindow implements both GtkWidget and GtkNative. }
function gtk4_widget_get_native(widget: PGtkWidget): PGtkWidget; cdecl;
  external LazGtk4C_library name 'gtk_widget_get_native';

{ GTK4: Returns the offset from the surface origin to the native widget's
  content area origin. This accounts for CSD (client-side decorations). }
procedure gtk4_native_get_surface_transform(native: PGtkWidget;
  x: Pgdouble; y: Pgdouble); cdecl;
  external LazGtk4C_library name 'gtk_native_get_surface_transform';

{ GTK4: Returns the GtkNative widget that owns the given GdkSurface.
  Used to find the CSD offset for a surface returned by
  gdk_device_get_surface_at_position. Available since GTK 4.0. }
function gtk4_native_get_for_surface(surface: PGdkWindow): PGtkWidget; cdecl;
  external LazGtk4C_library name 'gtk_native_get_for_surface';

{ ---- Widget child iteration (GTK4: replaces gtk_container_get_children) ---- }

{ GTK4: GtkContainer was removed. Use widget child/sibling iteration instead. }
function gtk4_widget_get_first_child(widget: PGtkWidget): PGtkWidget; cdecl;
  external LazGtk4C_library name 'gtk_widget_get_first_child';

function gtk4_widget_get_next_sibling(widget: PGtkWidget): PGtkWidget; cdecl;
  external LazGtk4C_library name 'gtk_widget_get_next_sibling';

{ ---- Widget measurement (GTK4: replaces get_preferred_width/height) ---- }

{ GTK4: gtk_widget_get_preferred_width/height were removed.
  Use gtk_widget_measure instead. Pass for_size=-1 for unconstrained measurement.
  minimum_baseline/natural_baseline can be nil if not needed. }
procedure gtk4_widget_measure(widget: PGtkWidget; orientation: TGtkOrientation;
  for_size: gint; minimum: Pgint; natural: Pgint;
  minimum_baseline: Pgint; natural_baseline: Pgint); cdecl;
  external LazGtk4C_library name 'gtk_widget_measure';

{ ---- GtkPopoverMenuBar (GTK4: replaces GtkMenuBar) ---- }

{ GTK4: GtkMenuBar was removed. Use GtkPopoverMenuBar with a GMenuModel. }
function gtk4_popover_menu_bar_new_from_model(model: PGMenuModel): PGtkWidget; cdecl;
  external LazGtk4C_library name 'gtk_popover_menu_bar_new_from_model';

procedure gtk4_popover_menu_bar_set_menu_model(bar: PGtkWidget; model: PGMenuModel); cdecl;
  external LazGtk4C_library name 'gtk_popover_menu_bar_set_menu_model';

function gtk4_popover_menu_bar_get_type: TGType; cdecl;
  external LazGtk4C_library name 'gtk_popover_menu_bar_get_type';

{ ---- GtkPopoverMenu (GTK4: replaces GtkMenu for popups) ---- }

function gtk4_popover_menu_new_from_model(model: PGMenuModel): PGtkWidget; cdecl;
  external LazGtk4C_library name 'gtk_popover_menu_new_from_model';

{ ---- GtkPopover (GTK4: set_parent replaces relative_to constructor param) ---- }

{ GTK4: gtk_popover_new() takes no params. Use set_parent() to attach. }
function gtk4_popover_new: PGtkWidget; cdecl;
  external LazGtk4C_library name 'gtk_popover_new';

procedure gtk4_popover_set_child(popover: PGtkWidget; child: PGtkWidget); cdecl;
  external LazGtk4C_library name 'gtk_popover_set_child';

procedure gtk4_popover_set_position(popover: PGtkWidget; position: TGtkPositionType); cdecl;
  external LazGtk4C_library name 'gtk_popover_set_position';

{ ---- GtkPopover positioning ---- }

procedure gtk4_popover_set_pointing_to(popover: PGtkWidget; rect: PGdkRectangle); cdecl;
  external LazGtk4C_library name 'gtk_popover_set_pointing_to';

procedure gtk4_popover_set_has_arrow(popover: PGtkWidget; has_arrow: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_popover_set_has_arrow';

{ Shift the popover from its computed position (applied through
  gdk_popup_layout_set_offset; the GDK slide/flip anchor hints still keep
  the surface visible). Used for TPopupMenu.Alignment. }
procedure gtk4_popover_set_offset(popover: PGtkWidget; x_offset: gint; y_offset: gint); cdecl;
  external LazGtk4C_library name 'gtk_popover_set_offset';

procedure gtk4_popover_popup(popover: PGtkWidget); cdecl;
  external LazGtk4C_library name 'gtk_popover_popup';

procedure gtk4_popover_popdown(popover: PGtkWidget); cdecl;
  external LazGtk4C_library name 'gtk_popover_popdown';

{ ---- GtkImage (GTK4: new_from_icon_name takes 1 param, no GtkIconSize) ---- }

function gtk4_image_new_from_icon_name(icon_name: Pgchar): PGtkWidget; cdecl;
  external LazGtk4C_library name 'gtk_image_new_from_icon_name';

{ ---- GtkButton (GTK4: set_child replaces set_image) ---- }

procedure gtk4_button_set_child(button: PGtkButton; child: PGtkWidget); cdecl;
  external LazGtk4C_library name 'gtk_button_set_child';

function gtk4_button_get_child(button: PGtkButton): PGtkWidget; cdecl;
  external LazGtk4C_library name 'gtk_button_get_child';

{ ---- GtkWindow (GTK4-only queries) ---- }

function gtk4_window_is_fullscreen(window: PGtkWindow): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_window_is_fullscreen';

{ ---- GdkDevice cursor position (GTK4: replaces gdk_device_get_position) ---- }

{ GTK4: Returns the surface under the device + surface-relative coordinates.
  Returns nil if the device is not over any surface. }
function gdk4_device_get_surface_at_position(device: PGdkDevice;
  win_x: Pdouble; win_y: Pdouble): PGdkWindow; cdecl;
  external LazGdk4_library name 'gdk_device_get_surface_at_position';

{ ---- GBytes (fix incorrect bindings - data param should be pointer, not guint8) ---- }

function glib2_bytes_new(data: Pointer; size: gsize): PGBytes; cdecl;
  external LazGLib2_library name 'g_bytes_new';

function glib2_bytes_get_data(bytes: PGBytes; size: Pgsize): Pointer; cdecl;
  external LazGLib2_library name 'g_bytes_get_data';

{ ---- GdkClipboard (GTK4: replaces GtkClipboard + GdkAtom) ---- }

type
  { Opaque types for GTK4 APIs }
  PGdkClipboard = Pointer;
  PGdkContentProvider = Pointer;
  PPGdkContentProvider = ^PGdkContentProvider;
  PGdkContentFormats = Pointer;
  PGdkTexture = Pointer;
  PGdkPaintable = Pointer;
  PGtkSnapshot = Pointer;

{ Get the clipboard for a display }
function gdk4_display_get_clipboard(display: PGdkDisplay): PGdkClipboard; cdecl;
  external LazGdk4_library name 'gdk_display_get_clipboard';

function gdk4_display_get_primary_clipboard(display: PGdkDisplay): PGdkClipboard; cdecl;
  external LazGdk4_library name 'gdk_display_get_primary_clipboard';

{ Clipboard text operations }
procedure gdk4_clipboard_set_text(clipboard: PGdkClipboard; text: PgChar); cdecl;
  external LazGdk4_library name 'gdk_clipboard_set_text';

procedure gdk4_clipboard_read_text_async(clipboard: PGdkClipboard;
  cancellable: PGCancellable; callback: TGAsyncReadyCallback; user_data: gpointer); cdecl;
  external LazGdk4_library name 'gdk_clipboard_read_text_async';

function gdk4_clipboard_read_text_finish(clipboard: PGdkClipboard;
  result_: PGAsyncResult; error: PPGError): PgChar; cdecl;
  external LazGdk4_library name 'gdk_clipboard_read_text_finish';

{ Clipboard content provider operations }
function gdk4_clipboard_set_content(clipboard: PGdkClipboard;
  provider: PGdkContentProvider): gboolean; cdecl;
  external LazGdk4_library name 'gdk_clipboard_set_content';

function gdk4_clipboard_get_formats(clipboard: PGdkClipboard): PGdkContentFormats; cdecl;
  external LazGdk4_library name 'gdk_clipboard_get_formats';

function gdk4_clipboard_is_local(clipboard: PGdkClipboard): gboolean; cdecl;
  external LazGdk4_library name 'gdk_clipboard_is_local';

{ Content provider creation }
function gdk4_content_provider_new_for_bytes(mime_type: PgChar;
  bytes: PGBytes): PGdkContentProvider; cdecl;
  external LazGdk4_library name 'gdk_content_provider_new_for_bytes';

function gdk4_content_provider_new_union(providers: PPGdkContentProvider;
  n_providers: gsize): PGdkContentProvider; cdecl;
  external LazGdk4_library name 'gdk_content_provider_new_union';

{ Content formats queries }
function gdk4_content_formats_contain_mime_type(formats: PGdkContentFormats;
  mime_type: PgChar): gboolean; cdecl;
  external LazGdk4_library name 'gdk_content_formats_contain_mime_type';

function gdk4_content_formats_get_mime_types(formats: PGdkContentFormats;
  n_mime_types: Pgsize): PPgChar; cdecl;
  external LazGdk4_library name 'gdk_content_formats_get_mime_types';

{ Clipboard async read for arbitrary mime types }
procedure gdk4_clipboard_read_async(clipboard: PGdkClipboard;
  mime_types: PPgChar; io_priority: gint; cancellable: PGCancellable;
  callback: TGAsyncReadyCallback; user_data: gpointer); cdecl;
  external LazGdk4_library name 'gdk_clipboard_read_async';

function gdk4_clipboard_read_finish(clipboard: PGdkClipboard;
  result_: PGAsyncResult; out_mime_type: PPgChar; error: PPGError): PGInputStream; cdecl;
  external LazGdk4_library name 'gdk_clipboard_read_finish';

{ ---- GdkCursor (GTK4: gdk_cursor_new_from_pixbuf removed, use texture) ---- }

{ GTK4: gdk_cursor_new_from_pixbuf was removed.
  Use gdk_texture_new_for_pixbuf to convert pixbuf to texture, then
  gdk_cursor_new_from_texture to create the cursor. }
function gdk4_texture_new_for_pixbuf(pixbuf: PGdkPixbuf): PGdkTexture; cdecl;
  external LazGdk4_library name 'gdk_texture_new_for_pixbuf';

function gdk4_cursor_new_from_texture(texture: PGdkTexture; hotspot_x: gint;
  hotspot_y: gint; fallback: PGdkCursor): PGdkCursor; cdecl;
  external LazGdk4_library name 'gdk_cursor_new_from_texture';

{ ---- GdkTexture / GdkMemoryTexture (GTK4: replaces GdkPixbuf) ---- }

type
  { GdkMemoryFormat — pixel format for GdkMemoryTexture }
  TGdkMemoryFormat = (
    GDK_MEMORY_B8G8R8A8_PREMULTIPLIED,
    GDK_MEMORY_A8R8G8B8_PREMULTIPLIED,
    GDK_MEMORY_R8G8B8A8_PREMULTIPLIED,
    GDK_MEMORY_B8G8R8A8,
    GDK_MEMORY_A8R8G8B8,
    GDK_MEMORY_R8G8B8A8,
    GDK_MEMORY_A8B8G8R8,
    GDK_MEMORY_R8G8B8,
    GDK_MEMORY_B8G8R8,
    GDK_MEMORY_R16G16B16,
    GDK_MEMORY_R16G16B16A16_PREMULTIPLIED,
    GDK_MEMORY_R16G16B16A16,
    GDK_MEMORY_R16G16B16_FLOAT,
    GDK_MEMORY_R16G16B16A16_FLOAT_PREMULTIPLIED,
    GDK_MEMORY_R16G16B16A16_FLOAT,
    GDK_MEMORY_R32G32B32_FLOAT,
    GDK_MEMORY_R32G32B32A32_FLOAT_PREMULTIPLIED,
    GDK_MEMORY_R32G32B32A32_FLOAT,
    GDK_MEMORY_N_FORMATS
  );

{ Get texture dimensions }
function gdk4_texture_get_width(texture: PGdkTexture): gint; cdecl;
  external LazGdk4_library name 'gdk_texture_get_width';

function gdk4_texture_get_height(texture: PGdkTexture): gint; cdecl;
  external LazGdk4_library name 'gdk_texture_get_height';

{ Download texture pixels into a buffer.
  data must be large enough for height * stride bytes.
  stride is the row stride in bytes (width * bytes_per_pixel, aligned). }
procedure gdk4_texture_download(texture: PGdkTexture;
  data: Pguchar; stride: gsize); cdecl;
  external LazGdk4_library name 'gdk_texture_download';

{ Save texture as PNG file (returns TRUE on success) }
function gdk4_texture_save_to_png(texture: PGdkTexture;
  filename: Pgchar): gboolean; cdecl;
  external LazGdk4_library name 'gdk_texture_save_to_png';

{ Save texture to PNG bytes (returns GBytes, caller must unref) }
function gdk4_texture_save_to_png_bytes(texture: PGdkTexture): PGBytes; cdecl;
  external LazGdk4_library name 'gdk_texture_save_to_png_bytes';

{ Create a GdkMemoryTexture from raw pixel data.
  bytes: GBytes containing pixel data (reffed internally).
  format: pixel format (e.g., GDK_MEMORY_R8G8B8A8).
  stride: row stride in bytes. }
function gdk4_memory_texture_new(width: gint; height: gint;
  format: TGdkMemoryFormat; bytes: PGBytes; stride: gsize): PGdkTexture; cdecl;
  external LazGdk4_library name 'gdk_memory_texture_new';

{ Create a texture from a GFile (PNG/JPEG/etc.) }
function gdk4_texture_new_from_file(file_: PGFile;
  error: PPGError): PGdkTexture; cdecl;
  external LazGdk4_library name 'gdk_texture_new_from_file';

{ Create a texture from a filename }
function gdk4_texture_new_from_filename(path: Pgchar;
  error: PPGError): PGdkTexture; cdecl;
  external LazGdk4_library name 'gdk_texture_new_from_filename';

{ Create a texture from a GResource path }
function gdk4_texture_new_from_resource(resource_path: Pgchar): PGdkTexture; cdecl;
  external LazGdk4_library name 'gdk_texture_new_from_resource';

{ ---- GtkFileChooser filter enumeration (GTK4: list_filters removed) ---- }

{ GTK4: gtk_file_chooser_list_filters was removed.
  Use gtk_file_chooser_get_filters which returns a GListModel. }
function gtk4_file_chooser_get_filters(chooser: PGtkFileChooser): PGListModel; cdecl;
  external LazGtk4C_library name 'gtk_file_chooser_get_filters';

{ ---- GtkFileChooser (GTK4: filename/URI APIs removed, use GFile) ---- }

{ GTK4: gtk_file_chooser_set_current_folder signature changed from (chooser, Pgchar)
  to (chooser, GFile*, GError**). The lazgtk4.pas binding has the old GTK3 signature. }
function gtk4_file_chooser_set_current_folder(chooser: PGtkFileChooser;
  file_: PGFile; error: PPGError): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_file_chooser_set_current_folder';

{ GTK4: gtk_file_chooser_get_current_folder now returns GFile* instead of Pgchar. }
function gtk4_file_chooser_get_current_folder(chooser: PGtkFileChooser): PGFile; cdecl;
  external LazGtk4C_library name 'gtk_file_chooser_get_current_folder';

{ GTK4: gtk_file_chooser_get_filename removed. Use get_file + g_file_get_path. }
function gtk4_file_chooser_get_file(chooser: PGtkFileChooser): PGFile; cdecl;
  external LazGtk4C_library name 'gtk_file_chooser_get_file';

{ GTK4: gtk_file_chooser_set_filename removed. Use set_file. }
function gtk4_file_chooser_set_file(chooser: PGtkFileChooser;
  file_: PGFile; error: PPGError): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_file_chooser_set_file';

{ GTK4: gtk_file_chooser_get_filenames removed. Use get_files (returns GListModel). }
function gtk4_file_chooser_get_files(chooser: PGtkFileChooser): PGListModel; cdecl;
  external LazGtk4C_library name 'gtk_file_chooser_get_files';

{ ---- GtkSnapshot / GskRenderNode (GTK4 snapshot rendering pipeline) ---- }
{ Note: graphene_point_t, graphene_size_t, graphene_rect_t are declared
  in the type section above (used by both compute_bounds and snapshot APIs) }

{ GTK4: Create a new snapshot object for building render nodes }
function gtk4_snapshot_new: PGtkSnapshot; cdecl;
  external LazGtk4C_library name 'gtk_snapshot_new';

{ GTK4: Consume snapshot and return the resulting render node (or nil if empty).
  The snapshot is freed by this call. }
function gtk4_snapshot_free_to_node(snapshot: PGtkSnapshot): PGskRenderNode; cdecl;
  external LazGtk4C_library name 'gtk_snapshot_free_to_node';

{ GTK4: Draw a render node to a cairo context }
procedure gsk4_render_node_draw(node: PGskRenderNode; cr: Pcairo_t); cdecl;
  external LazGtk4C_library name 'gsk_render_node_draw';

{ GTK4: Unref a render node }
procedure gsk4_render_node_unref(node: PGskRenderNode); cdecl;
  external LazGtk4C_library name 'gsk_render_node_unref';

{ GTK4: Append a cairo drawing node to the snapshot.
  Returns a cairo_t that is valid until cairo_destroy is called on it.
  All cairo drawing on the returned context will be part of the GSK render tree. }
function gtk4_snapshot_append_cairo(snapshot: PGtkSnapshot;
  const bounds: Pgraphene_rect_t): Pcairo_t; cdecl;
  external LazGtk4C_library name 'gtk_snapshot_append_cairo';

{ GTK4: Snapshot a child widget within a parent's snapshot vfunc.
  Handles coordinate translation and visibility checks.
  Must be called from within the parent widget's snapshot vfunc. }
procedure gtk4_widget_snapshot_child(widget: PGtkWidget; child: PGtkWidget;
  snapshot: PGtkSnapshot); cdecl;
  external LazGtk4C_library name 'gtk_widget_snapshot_child';

{ ---- GdkPaintable (GTK4 paintable interface) ---- }

{ GTK4: Snapshot a paintable into a snapshot object }
procedure gdk4_paintable_snapshot(paintable: PGdkPaintable; snapshot: PGtkSnapshot;
  width: double; height: double); cdecl;
  external LazGtk4C_library name 'gdk_paintable_snapshot';

{ ---- GtkWidgetPaintable (GTK4: captures widget rendering as GdkPaintable) ---- }

{ GTK4: Create a GdkPaintable that renders a widget. Returns a GObject (unref when done). }
function gtk4_widget_paintable_new(widget: PGtkWidget): PGdkPaintable; cdecl;
  external LazGtk4C_library name 'gtk_widget_paintable_new';

{ ---- Widget cursor (GTK4: replaces gdk_window_set_cursor) ---- }

{ GTK4: Set the cursor for a widget. Pass nil to reset to default.
  Note: lazgdk4.pas has the wrong GTK3 signature (display, name). }
procedure gtk4_widget_set_cursor(widget: PGtkWidget; cursor: PGdkCursor); cdecl;
  external LazGtk4C_library name 'gtk_widget_set_cursor';

{ GTK4: can_focus vs focusable — In GTK4, grab_focus checks the 'focusable'
  property (priv->focusable), NOT 'can-focus'. can_focus is a container-level
  hint meaning "this subtree may contain focusable widgets". focusable means
  "this specific widget itself can receive keyboard focus". }
procedure gtk4_widget_set_focusable(widget: PGtkWidget; focusable: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_widget_set_focusable';
function gtk4_widget_get_focusable(widget: PGtkWidget): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_widget_get_focusable';

{ GTK4: gtk_im_context_set_client_widget — associate an IM context with a widget.
  GTK4's GtkEventControllerKey.set_im_context does NOT call this (unlike GTK3).
  Native text widgets (GtkText, GtkTextView) call it in their realize handler.
  For custom widgets using GtkEventControllerKey with an external IMContext,
  we must call it explicitly so the IM backend (ibus/fcitx) can get the widget's
  GDK surface/display and operate correctly (especially for CJK composition). }
procedure gtk4_im_context_set_client_widget(context: PGtkIMContext; widget: PGtkWidget); cdecl;
  external LazGtk4C_library name 'gtk_im_context_set_client_widget';

{ GTK4: gdk_cursor_new_from_name changed from (display, name) to (name, fallback) }
function gdk4_cursor_new_from_name(name: Pgchar; fallback: PGdkCursor): PGdkCursor; cdecl;
  external LazGdk4_library name 'gdk_cursor_new_from_name';

{ ---- Widget action activation (GTK4: replaces various action APIs) ---- }
function gtk4_widget_activate_action(widget: PGtkWidget; name: Pgchar; format_string: Pgchar): gboolean; cdecl; varargs;
  external LazGtk4C_library name 'gtk_widget_activate_action';

{ ---- GtkTextBuffer undo/redo (GTK4-only) ---- }

procedure gtk4_text_buffer_set_enable_undo(buffer: PGtkTextBuffer; enable_undo: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_text_buffer_set_enable_undo';

function gtk4_text_buffer_get_enable_undo(buffer: PGtkTextBuffer): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_text_buffer_get_enable_undo';

procedure gtk4_text_buffer_undo(buffer: PGtkTextBuffer); cdecl;
  external LazGtk4C_library name 'gtk_text_buffer_undo';

procedure gtk4_text_buffer_redo(buffer: PGtkTextBuffer); cdecl;
  external LazGtk4C_library name 'gtk_text_buffer_redo';

function gtk4_text_buffer_get_can_undo(buffer: PGtkTextBuffer): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_text_buffer_get_can_undo';

function gtk4_text_buffer_get_can_redo(buffer: PGtkTextBuffer): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_text_buffer_get_can_redo';

{ ---- GtkDropTarget (GTK4: replaces gtk_drag_dest_set for receiving drops) ---- }

{ GTK4: Create a new drop target controller.
  type_ = GType of expected data (use gdk4_file_list_get_type for file drops).
  actions = allowed drop actions (GDK_ACTION_COPY, GDK_ACTION_MOVE, etc.).
  Signals: 'accept' (gboolean), 'enter'/'motion' (GdkDragAction), 'leave', 'drop' (gboolean).
  The 'drop' signal receives (GtkDropTarget, GValue, gdouble x, gdouble y) → gboolean. }
function gtk4_drop_target_new(type_: TGType; actions: TGdkDragAction): PGtkEventController; cdecl;
  external LazGtk4C_library name 'gtk_drop_target_new';

{ ---- GdkFileList (GTK4: boxed type wrapping GSList of GFile) ---- }

{ GTK4: Get GType for GdkFileList (used with GtkDropTarget for file drops) }
function gdk4_file_list_get_type: TGType; cdecl;
  external LazGdk4_library name 'gdk_file_list_get_type';

{ GTK4: Get the GSList of GFile objects from a GdkFileList.
  The returned list is owned by the GdkFileList — do not free. }
function gdk4_file_list_get_files(file_list: Pointer): PGSList; cdecl;
  external LazGdk4_library name 'gdk_file_list_get_files';

{ ---- GTK4 Drag & Drop types ---- }
type
  PGdkDrag = Pointer;       { GTK4: replaces PGdkDragContext for drag source side }
  PGdkDrop = Pointer;       { GTK4: new, drop target side }
  PGtkDragSource = Pointer; { GTK4: event controller for initiating drags }
  PGtkDropTargetAsync = Pointer; { GTK4: async drop target controller }

{ ---- GtkDragSource (GTK4: event controller for initiating drags) ---- }

{ Create a new drag source controller.
  Signals: 'prepare' → PGdkContentProvider, 'drag-begin' (GdkDrag),
  'drag-end' (GdkDrag, gboolean delete_data), 'drag-cancel' (GdkDrag, GdkDragCancelReason) → gboolean }
function gtk4_drag_source_new: PGtkEventController; cdecl;
  external LazGtk4C_library name 'gtk_drag_source_new';

procedure gtk4_drag_source_set_content(source: PGtkDragSource;
  content: PGdkContentProvider); cdecl;
  external LazGtk4C_library name 'gtk_drag_source_set_content';

function gtk4_drag_source_get_content(source: PGtkDragSource): PGdkContentProvider; cdecl;
  external LazGtk4C_library name 'gtk_drag_source_get_content';

procedure gtk4_drag_source_set_actions(source: PGtkDragSource;
  actions: TGdkDragAction); cdecl;
  external LazGtk4C_library name 'gtk_drag_source_set_actions';

function gtk4_drag_source_get_actions(source: PGtkDragSource): TGdkDragAction; cdecl;
  external LazGtk4C_library name 'gtk_drag_source_get_actions';

{ Set icon shown during drag (paintable = texture/icon, hot_x/hot_y = cursor offset) }
procedure gtk4_drag_source_set_icon(source: PGtkDragSource;
  paintable: PGdkPaintable; hot_x: gint; hot_y: gint); cdecl;
  external LazGtk4C_library name 'gtk_drag_source_set_icon';

procedure gtk4_drag_source_drag_cancel(source: PGtkDragSource); cdecl;
  external LazGtk4C_library name 'gtk_drag_source_drag_cancel';

function gtk4_drag_source_get_drag(source: PGtkDragSource): PGdkDrag; cdecl;
  external LazGtk4C_library name 'gtk_drag_source_get_drag';

{ ---- GtkDropTarget extensions (GTK4: additional to gtk_drop_target_new) ---- }

procedure gtk4_drop_target_set_gtypes(self: PGtkEventController;
  types: PGType; n_types: gsize); cdecl;
  external LazGtk4C_library name 'gtk_drop_target_set_gtypes';

procedure gtk4_drop_target_set_actions(self: PGtkEventController;
  actions: TGdkDragAction); cdecl;
  external LazGtk4C_library name 'gtk_drop_target_set_actions';

function gtk4_drop_target_get_actions(self: PGtkEventController): TGdkDragAction; cdecl;
  external LazGtk4C_library name 'gtk_drop_target_get_actions';

{ Get the value being dropped (only valid in 'drop' signal handler) }
function gtk4_drop_target_get_value(self: PGtkEventController): PGValue; cdecl;
  external LazGtk4C_library name 'gtk_drop_target_get_value';

{ Get the GdkDrop object for the current drop operation }
function gtk4_drop_target_get_current_drop(self: PGtkEventController): PGdkDrop; cdecl;
  external LazGtk4C_library name 'gtk_drop_target_get_current_drop';

{ Reject the current drop (call from 'enter' or 'motion' signal) }
procedure gtk4_drop_target_reject(self: PGtkEventController); cdecl;
  external LazGtk4C_library name 'gtk_drop_target_reject';

{ ---- GtkDropTargetAsync (GTK4: for async drops with content formats) ---- }

function gtk4_drop_target_async_new(formats: PGdkContentFormats;
  actions: TGdkDragAction): PGtkEventController; cdecl;
  external LazGtk4C_library name 'gtk_drop_target_async_new';

procedure gtk4_drop_target_async_set_formats(self: PGtkDropTargetAsync;
  formats: PGdkContentFormats); cdecl;
  external LazGtk4C_library name 'gtk_drop_target_async_set_formats';

procedure gtk4_drop_target_async_set_actions(self: PGtkDropTargetAsync;
  actions: TGdkDragAction); cdecl;
  external LazGtk4C_library name 'gtk_drop_target_async_set_actions';

procedure gtk4_drop_target_async_reject_drop(self: PGtkDropTargetAsync;
  drop: PGdkDrop); cdecl;
  external LazGtk4C_library name 'gtk_drop_target_async_reject_drop';

{ ---- GdkDrop (GTK4: drop-side object, replaces parts of GdkDragContext) ---- }

function gdk4_drop_get_actions(self: PGdkDrop): TGdkDragAction; cdecl;
  external LazGdk4_library name 'gdk_drop_get_actions';

{ Report which of the offered actions are accepted }
procedure gdk4_drop_status(self: PGdkDrop; actions: TGdkDragAction;
  preferred: TGdkDragAction); cdecl;
  external LazGdk4_library name 'gdk_drop_status';

{ Report success/failure of the drop operation }
procedure gdk4_drop_finish(self: PGdkDrop; action: TGdkDragAction); cdecl;
  external LazGdk4_library name 'gdk_drop_finish';

{ Get the GdkDrag if the drop comes from the same application (nil if cross-app) }
function gdk4_drop_get_drag(self: PGdkDrop): PGdkDrag; cdecl;
  external LazGdk4_library name 'gdk_drop_get_drag';

function gdk4_drop_get_formats(self: PGdkDrop): PGdkContentFormats; cdecl;
  external LazGdk4_library name 'gdk_drop_get_formats';

function gdk4_drop_get_surface(self: PGdkDrop): PGdkWindow{PGdkSurface}; cdecl;
  external LazGdk4_library name 'gdk_drop_get_surface';

{ Async read: read drop contents as input stream }
procedure gdk4_drop_read_async(self: PGdkDrop; mime_types: PPgchar;
  io_priority: gint; cancellable: PGCancellable;
  callback: TGAsyncReadyCallback; user_data: gpointer); cdecl;
  external LazGdk4_library name 'gdk_drop_read_async';

function gdk4_drop_read_finish(self: PGdkDrop; result_: PGAsyncResult;
  out_mime_type: PPgchar; error: PPGError): PGInputStream; cdecl;
  external LazGdk4_library name 'gdk_drop_read_finish';

{ Async read: read drop value (e.g., text, file list) }
procedure gdk4_drop_read_value_async(self: PGdkDrop; type_: TGType;
  io_priority: gint; cancellable: PGCancellable;
  callback: TGAsyncReadyCallback; user_data: gpointer); cdecl;
  external LazGdk4_library name 'gdk_drop_read_value_async';

function gdk4_drop_read_value_finish(self: PGdkDrop;
  result_: PGAsyncResult; error: PPGError): PGValue; cdecl;
  external LazGdk4_library name 'gdk_drop_read_value_finish';

{ ---- GdkDrag (GTK4: drag-side object, replaces parts of GdkDragContext) ---- }

function gdk4_drag_get_actions(self: PGdkDrag): TGdkDragAction; cdecl;
  external LazGdk4_library name 'gdk_drag_get_actions';

function gdk4_drag_get_selected_action(self: PGdkDrag): TGdkDragAction; cdecl;
  external LazGdk4_library name 'gdk_drag_get_selected_action';

procedure gdk4_drag_set_hotspot(self: PGdkDrag; hot_x: gint; hot_y: gint); cdecl;
  external LazGdk4_library name 'gdk_drag_set_hotspot';

function gdk4_drag_get_content(self: PGdkDrag): PGdkContentProvider; cdecl;
  external LazGdk4_library name 'gdk_drag_get_content';

function gdk4_drag_get_formats(self: PGdkDrag): PGdkContentFormats; cdecl;
  external LazGdk4_library name 'gdk_drag_get_formats';

function gdk4_drag_get_surface(self: PGdkDrag): PGdkWindow{PGdkSurface}; cdecl;
  external LazGdk4_library name 'gdk_drag_get_surface';

procedure gdk4_drag_drop_done(self: PGdkDrag; success: gboolean); cdecl;
  external LazGdk4_library name 'gdk_drag_drop_done';

{ ---- GdkContentProvider additions ---- }

{ Create a content provider for a GValue }
function gdk4_content_provider_new_for_value(value: PGValue): PGdkContentProvider; cdecl;
  external LazGdk4_library name 'gdk_content_provider_new_for_value';

{ ---- GdkContentFormats additions ---- }

{ Create content formats from an array of mime types }
function gdk4_content_formats_new(mime_types: PPgchar;
  n_mime_types: guint): PGdkContentFormats; cdecl;
  external LazGdk4_library name 'gdk_content_formats_new';

{ Create content formats for a single GType }
function gdk4_content_formats_new_for_gtype(type_: TGType): PGdkContentFormats; cdecl;
  external LazGdk4_library name 'gdk_content_formats_new_for_gtype';

{ Check if a GType is contained in the formats }
function gdk4_content_formats_contain_gtype(formats: PGdkContentFormats;
  type_: TGType): gboolean; cdecl;
  external LazGdk4_library name 'gdk_content_formats_contain_gtype';

procedure gdk4_content_formats_ref(formats: PGdkContentFormats); cdecl;
  external LazGdk4_library name 'gdk_content_formats_ref';

procedure gdk4_content_formats_unref(formats: PGdkContentFormats); cdecl;
  external LazGdk4_library name 'gdk_content_formats_unref';

{ Utility: check if drag threshold has been exceeded }
function gtk4_drag_check_threshold(widget: PGtkWidget;
  start_x: gint; start_y: gint; current_x: gint; current_y: gint): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_drag_check_threshold';

{ ---- GtkShortcutController (GTK4: replaces gtk_widget_add_accelerator) ---- }

type
  PGtkShortcutController = ^TGtkShortcutController;
  TGtkShortcutController = record end;

  PGtkShortcut = ^TGtkShortcut;
  TGtkShortcut = record end;

  PGtkShortcutTrigger = ^TGtkShortcutTrigger;
  TGtkShortcutTrigger = record end;

  PGtkShortcutAction = ^TGtkShortcutAction;
  TGtkShortcutAction = record end;

  { Callback type for gtk_callback_action_new }
  TGtkShortcutFunc = function(widget: PGtkWidget; args: Pointer{PGVariant};
    user_data: gpointer): gboolean; cdecl;

{ Create a new shortcut controller }
function gtk4_shortcut_controller_new: PGtkEventController; cdecl;
  external LazGtk4C_library name 'gtk_shortcut_controller_new';

{ Add a shortcut to the controller (ownership of shortcut transferred) }
procedure gtk4_shortcut_controller_add_shortcut(controller: PGtkShortcutController;
  shortcut: PGtkShortcut); cdecl;
  external LazGtk4C_library name 'gtk_shortcut_controller_add_shortcut';

{ Remove a shortcut from the controller }
procedure gtk4_shortcut_controller_remove_shortcut(controller: PGtkShortcutController;
  shortcut: PGtkShortcut); cdecl;
  external LazGtk4C_library name 'gtk_shortcut_controller_remove_shortcut';

{ Create a new shortcut (ownership of trigger and action transferred) }
function gtk4_shortcut_new(trigger: PGtkShortcutTrigger;
  action: PGtkShortcutAction): PGtkShortcut; cdecl;
  external LazGtk4C_library name 'gtk_shortcut_new';

{ Create a keyval trigger (matches a key with modifiers) }
function gtk4_keyval_trigger_new(keyval: guint;
  modifiers: TGdkModifierType): PGtkShortcutTrigger; cdecl;
  external LazGtk4C_library name 'gtk_keyval_trigger_new';

{ Get the activate action singleton (calls gtk_widget_activate) }
function gtk4_activate_action_get: PGtkShortcutAction; cdecl;
  external LazGtk4C_library name 'gtk_activate_action_get';

{ Create a callback action }
function gtk4_callback_action_new(callback: TGtkShortcutFunc;
  data: gpointer; destroy: TGDestroyNotify): PGtkShortcutAction; cdecl;
  external LazGtk4C_library name 'gtk_callback_action_new';

{ Set the scope of the shortcut controller (local/managed/global) }
const
  GTK_SHORTCUT_SCOPE_LOCAL   = 0;
  GTK_SHORTCUT_SCOPE_MANAGED = 1;
  GTK_SHORTCUT_SCOPE_GLOBAL  = 2;

procedure gtk4_shortcut_controller_set_scope(controller: PGtkShortcutController;
  scope: gint); cdecl;
  external LazGtk4C_library name 'gtk_shortcut_controller_set_scope';

{ Set mnemonics modifier key (default: Alt) }
procedure gtk4_shortcut_controller_set_mnemonics_modifiers(
  controller: PGtkShortcutController; modifiers: TGdkModifierType); cdecl;
  external LazGtk4C_library name 'gtk_shortcut_controller_set_mnemonics_modifiers';

{ Parse a trigger string like "<Control>s", "<Primary><Shift>z" }
function gtk4_shortcut_trigger_parse_string(str: Pgchar): PGtkShortcutTrigger; cdecl;
  external LazGtk4C_library name 'gtk_shortcut_trigger_parse_string';

{ Create a mnemonic trigger (matches Alt+key) }
function gtk4_mnemonic_trigger_new(keyval: guint): PGtkShortcutTrigger; cdecl;
  external LazGtk4C_library name 'gtk_mnemonic_trigger_new';

{ Combine two triggers (matches if either fires) }
function gtk4_alternative_trigger_new(first: PGtkShortcutTrigger;
  second: PGtkShortcutTrigger): PGtkShortcutTrigger; cdecl;
  external LazGtk4C_library name 'gtk_alternative_trigger_new';

{ Get the never-trigger singleton (never matches) }
function gtk4_never_trigger_get: PGtkShortcutTrigger; cdecl;
  external LazGtk4C_library name 'gtk_never_trigger_get';

{ Create a signal action (emits the named signal on the widget) }
function gtk4_signal_action_new(signal_name: Pgchar): PGtkShortcutAction; cdecl;
  external LazGtk4C_library name 'gtk_signal_action_new';

{ Create a named action (activates a GAction by name, e.g., "win.save") }
function gtk4_named_action_new(name: Pgchar): PGtkShortcutAction; cdecl;
  external LazGtk4C_library name 'gtk_named_action_new';

{ Get the nothing-action singleton (suppresses default key handling) }
function gtk4_nothing_action_get: PGtkShortcutAction; cdecl;
  external LazGtk4C_library name 'gtk_nothing_action_get';

{ Get the mnemonic-action singleton (activates mnemonic) }
function gtk4_mnemonic_action_get: PGtkShortcutAction; cdecl;
  external LazGtk4C_library name 'gtk_mnemonic_action_get';

{ ---- Widget child ordering (GTK 4.0+) ---- }

{ Insert widget before sibling in the parent's child list (affects Z-order / paint order).
  If sibling is nil, widget is placed last. }
procedure gtk4_widget_insert_before(widget: PGtkWidget; parent: PGtkWidget;
  next_sibling: PGtkWidget); cdecl;
  external LazGtk4C_library name 'gtk_widget_insert_before';

{ Insert widget after sibling in the parent's child list.
  If sibling is nil, widget is placed first. }
procedure gtk4_widget_insert_after(widget: PGtkWidget; parent: PGtkWidget;
  prev_sibling: PGtkWidget); cdecl;
  external LazGtk4C_library name 'gtk_widget_insert_after';

{ Get the last child of a widget (first_child already declared above) }
function gtk4_widget_get_last_child(widget: PGtkWidget): PGtkWidget; cdecl;
  external LazGtk4C_library name 'gtk_widget_get_last_child';

{ Get the previous sibling of a widget (next_sibling already declared above) }
function gtk4_widget_get_prev_sibling(widget: PGtkWidget): PGtkWidget; cdecl;
  external LazGtk4C_library name 'gtk_widget_get_prev_sibling';

{ ===========================================================================
  GTK4 Modern Widget Bindings
  GtkDropDown, GtkColumnView, GtkListView and supporting infrastructure.
  These replace deprecated GtkComboBox / GtkTreeView in GTK4.
  =========================================================================== }

{ ---- Section 1: Opaque pointer type declarations ---- }

type
  PGtkExpression = Pointer;
  PGtkBitset = Pointer;
  PGtkSorter = Pointer;
  PGtkSelectionModel = Pointer;
  PGtkSingleSelection = Pointer;
  PGtkMultiSelection = Pointer;
  PGtkNoSelection = Pointer;
  PGtkStringList = Pointer;
  PGtkStringObject = Pointer;
  PGtkListItemFactory = Pointer;
  PGtkSignalListItemFactory = Pointer;
  PGtkListItem = Pointer;
  PGtkDropDown = Pointer;
  PGtkListView = Pointer;
  PGtkColumnView = Pointer;
  PGtkColumnViewColumn = Pointer;
  PGtkGridView = Pointer;
  PGtkFilter = Pointer;
  PGtkCustomFilter = Pointer;
  PGtkFilterListModel = Pointer;
  PGtkSortListModel = Pointer;

  TGCompareDataFunc = function(a: gconstpointer; b: gconstpointer;
    user_data: gpointer): gint; cdecl;

  { GtkCustomFilterFunc: returns TRUE to keep item, FALSE to filter it out }
  TGtkCustomFilterFunc = function(item: gpointer;
    user_data: gpointer): gboolean; cdecl;

  { GtkOrdering: comparison result for GtkSorter }
  TGtkOrdering = (
    GTK_ORDERING_SMALLER = -1,
    GTK_ORDERING_EQUAL = 0,
    GTK_ORDERING_LARGER = 1
  );

  { GtkSorterOrder: describes strictness of sorter ordering }
  TGtkSorterOrder = (
    GTK_SORTER_ORDER_PARTIAL,
    GTK_SORTER_ORDER_NONE,
    GTK_SORTER_ORDER_TOTAL
  );

  { GtkSorterChange: describes how a sorter changed }
  TGtkSorterChange = (
    GTK_SORTER_CHANGE_DIFFERENT,
    GTK_SORTER_CHANGE_INVERTED,
    GTK_SORTER_CHANGE_LESS_STRICT,
    GTK_SORTER_CHANGE_MORE_STRICT
  );

  { GtkFilterMatch: describes strictness of filter matching }
  TGtkFilterMatch = (
    GTK_FILTER_MATCH_SOME,
    GTK_FILTER_MATCH_NONE,
    GTK_FILTER_MATCH_ALL
  );

  { GtkFilterChange: describes how a filter changed }
  TGtkFilterChange = (
    GTK_FILTER_CHANGE_DIFFERENT,
    GTK_FILTER_CHANGE_LESS_STRICT,
    GTK_FILTER_CHANGE_MORE_STRICT
  );

const
  GTK_INVALID_LIST_POSITION = guint($FFFFFFFF);

{ ---- Section 2: Infrastructure — GtkSelectionModel (interface) ---- }

function gtk4_selection_model_is_selected(model: PGtkSelectionModel;
  position: guint): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_selection_model_is_selected';

function gtk4_selection_model_select_item(model: PGtkSelectionModel;
  position: guint; unselect_rest: gboolean): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_selection_model_select_item';

function gtk4_selection_model_unselect_item(model: PGtkSelectionModel;
  position: guint): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_selection_model_unselect_item';

function gtk4_selection_model_select_range(model: PGtkSelectionModel;
  position: guint; n_items: guint; unselect_rest: gboolean): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_selection_model_select_range';

function gtk4_selection_model_unselect_range(model: PGtkSelectionModel;
  position: guint; n_items: guint): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_selection_model_unselect_range';

function gtk4_selection_model_select_all(model: PGtkSelectionModel): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_selection_model_select_all';

function gtk4_selection_model_unselect_all(model: PGtkSelectionModel): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_selection_model_unselect_all';

function gtk4_selection_model_get_selection(model: PGtkSelectionModel): PGtkBitset; cdecl;
  external LazGtk4C_library name 'gtk_selection_model_get_selection';

function gtk4_selection_model_get_selection_in_range(model: PGtkSelectionModel;
  position: guint; n_items: guint): PGtkBitset; cdecl;
  external LazGtk4C_library name 'gtk_selection_model_get_selection_in_range';

procedure gtk4_selection_model_selection_changed(model: PGtkSelectionModel;
  position: guint; n_items: guint); cdecl;
  external LazGtk4C_library name 'gtk_selection_model_selection_changed';

function gtk4_multi_selection_get_type: TGType; cdecl;
  external LazGtk4C_library name 'gtk_multi_selection_get_type';

{ ---- GtkBitset ---- }

function gtk4_bitset_get_size(self: PGtkBitset): guint64; cdecl;
  external LazGtk4C_library name 'gtk_bitset_get_size';

function gtk4_bitset_get_minimum(self: PGtkBitset): guint; cdecl;
  external LazGtk4C_library name 'gtk_bitset_get_minimum';

function gtk4_bitset_get_nth(self: PGtkBitset; nth: guint): guint; cdecl;
  external LazGtk4C_library name 'gtk_bitset_get_nth';

function gtk4_bitset_contains(self: PGtkBitset; value: guint): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_bitset_contains';

procedure gtk4_bitset_unref(self: PGtkBitset); cdecl;
  external LazGtk4C_library name 'gtk_bitset_unref';

{ ---- GtkSingleSelection ---- }

function gtk4_single_selection_new(model: PGListModel): PGtkSingleSelection; cdecl;
  external LazGtk4C_library name 'gtk_single_selection_new';

function gtk4_single_selection_get_model(self: PGtkSingleSelection): PGListModel; cdecl;
  external LazGtk4C_library name 'gtk_single_selection_get_model';

procedure gtk4_single_selection_set_model(self: PGtkSingleSelection;
  model: PGListModel); cdecl;
  external LazGtk4C_library name 'gtk_single_selection_set_model';

function gtk4_single_selection_get_selected(self: PGtkSingleSelection): guint; cdecl;
  external LazGtk4C_library name 'gtk_single_selection_get_selected';

procedure gtk4_single_selection_set_selected(self: PGtkSingleSelection;
  position: guint); cdecl;
  external LazGtk4C_library name 'gtk_single_selection_set_selected';

function gtk4_single_selection_get_selected_item(self: PGtkSingleSelection): gpointer; cdecl;
  external LazGtk4C_library name 'gtk_single_selection_get_selected_item';

function gtk4_single_selection_get_autoselect(self: PGtkSingleSelection): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_single_selection_get_autoselect';

procedure gtk4_single_selection_set_autoselect(self: PGtkSingleSelection;
  autoselect: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_single_selection_set_autoselect';

function gtk4_single_selection_get_can_unselect(self: PGtkSingleSelection): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_single_selection_get_can_unselect';

procedure gtk4_single_selection_set_can_unselect(self: PGtkSingleSelection;
  can_unselect: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_single_selection_set_can_unselect';

{ ---- GtkMultiSelection ---- }

function gtk4_multi_selection_new(model: PGListModel): PGtkMultiSelection; cdecl;
  external LazGtk4C_library name 'gtk_multi_selection_new';

function gtk4_multi_selection_get_model(self: PGtkMultiSelection): PGListModel; cdecl;
  external LazGtk4C_library name 'gtk_multi_selection_get_model';

procedure gtk4_multi_selection_set_model(self: PGtkMultiSelection;
  model: PGListModel); cdecl;
  external LazGtk4C_library name 'gtk_multi_selection_set_model';

{ ---- GtkNoSelection ---- }

function gtk4_no_selection_new(model: PGListModel): PGtkNoSelection; cdecl;
  external LazGtk4C_library name 'gtk_no_selection_new';

function gtk4_no_selection_get_model(self: PGtkNoSelection): PGListModel; cdecl;
  external LazGtk4C_library name 'gtk_no_selection_get_model';

procedure gtk4_no_selection_set_model(self: PGtkNoSelection;
  model: PGListModel); cdecl;
  external LazGtk4C_library name 'gtk_no_selection_set_model';

{ ---- GtkStringList ---- }

function gtk4_string_list_new(strings: PPgchar): PGtkStringList; cdecl;
  external LazGtk4C_library name 'gtk_string_list_new';

procedure gtk4_string_list_append(self: PGtkStringList; str: Pgchar); cdecl;
  external LazGtk4C_library name 'gtk_string_list_append';

procedure gtk4_string_list_remove(self: PGtkStringList; position: guint); cdecl;
  external LazGtk4C_library name 'gtk_string_list_remove';

procedure gtk4_string_list_splice(self: PGtkStringList; position: guint;
  n_removals: guint; additions: PPgchar); cdecl;
  external LazGtk4C_library name 'gtk_string_list_splice';

procedure gtk4_string_list_take(self: PGtkStringList; str: Pgchar); cdecl;
  external LazGtk4C_library name 'gtk_string_list_take';

function gtk4_string_list_get_string(self: PGtkStringList;
  position: guint): Pgchar; cdecl;
  external LazGtk4C_library name 'gtk_string_list_get_string';

{ ---- GtkStringObject ---- }

function gtk4_string_object_new(str: Pgchar): PGtkStringObject; cdecl;
  external LazGtk4C_library name 'gtk_string_object_new';

function gtk4_string_object_get_string(self: PGtkStringObject): Pgchar; cdecl;
  external LazGtk4C_library name 'gtk_string_object_get_string';

{ ---- GtkSignalListItemFactory ---- }

function gtk4_signal_list_item_factory_new: PGtkSignalListItemFactory; cdecl;
  external LazGtk4C_library name 'gtk_signal_list_item_factory_new';

{ Signals: "setup", "bind", "unbind", "teardown" — connect via g_signal_connect }

{ ---- GtkListItem ---- }

function gtk4_list_item_get_item(self: PGtkListItem): gpointer; cdecl;
  external LazGtk4C_library name 'gtk_list_item_get_item';

function gtk4_list_item_get_position(self: PGtkListItem): guint; cdecl;
  external LazGtk4C_library name 'gtk_list_item_get_position';

function gtk4_list_item_get_selected(self: PGtkListItem): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_list_item_get_selected';

function gtk4_list_item_get_child(self: PGtkListItem): PGtkWidget; cdecl;
  external LazGtk4C_library name 'gtk_list_item_get_child';

procedure gtk4_list_item_set_child(self: PGtkListItem; child: PGtkWidget); cdecl;
  external LazGtk4C_library name 'gtk_list_item_set_child';

function gtk4_list_item_get_activatable(self: PGtkListItem): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_list_item_get_activatable';

procedure gtk4_list_item_set_activatable(self: PGtkListItem;
  activatable: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_list_item_set_activatable';

function gtk4_list_item_get_selectable(self: PGtkListItem): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_list_item_get_selectable';

procedure gtk4_list_item_set_selectable(self: PGtkListItem;
  selectable: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_list_item_set_selectable';

{ ---- Section 3: Widget bindings — GtkDropDown ---- }

function gtk4_drop_down_new(model: PGListModel;
  expression: PGtkExpression): PGtkWidget; cdecl;
  external LazGtk4C_library name 'gtk_drop_down_new';

function gtk4_drop_down_new_from_strings(strings: PPgchar): PGtkWidget; cdecl;
  external LazGtk4C_library name 'gtk_drop_down_new_from_strings';

function gtk4_drop_down_get_model(self: PGtkDropDown): PGListModel; cdecl;
  external LazGtk4C_library name 'gtk_drop_down_get_model';

procedure gtk4_drop_down_set_model(self: PGtkDropDown; model: PGListModel); cdecl;
  external LazGtk4C_library name 'gtk_drop_down_set_model';

function gtk4_drop_down_get_selected(self: PGtkDropDown): guint; cdecl;
  external LazGtk4C_library name 'gtk_drop_down_get_selected';

procedure gtk4_drop_down_set_selected(self: PGtkDropDown; position: guint); cdecl;
  external LazGtk4C_library name 'gtk_drop_down_set_selected';

function gtk4_drop_down_get_selected_item(self: PGtkDropDown): gpointer; cdecl;
  external LazGtk4C_library name 'gtk_drop_down_get_selected_item';

function gtk4_drop_down_get_factory(self: PGtkDropDown): PGtkListItemFactory; cdecl;
  external LazGtk4C_library name 'gtk_drop_down_get_factory';

procedure gtk4_drop_down_set_factory(self: PGtkDropDown;
  factory: PGtkListItemFactory); cdecl;
  external LazGtk4C_library name 'gtk_drop_down_set_factory';

function gtk4_drop_down_get_list_factory(self: PGtkDropDown): PGtkListItemFactory; cdecl;
  external LazGtk4C_library name 'gtk_drop_down_get_list_factory';

procedure gtk4_drop_down_set_list_factory(self: PGtkDropDown;
  factory: PGtkListItemFactory); cdecl;
  external LazGtk4C_library name 'gtk_drop_down_set_list_factory';

function gtk4_drop_down_get_expression(self: PGtkDropDown): PGtkExpression; cdecl;
  external LazGtk4C_library name 'gtk_drop_down_get_expression';

procedure gtk4_drop_down_set_expression(self: PGtkDropDown;
  expression: PGtkExpression); cdecl;
  external LazGtk4C_library name 'gtk_drop_down_set_expression';

function gtk4_drop_down_get_enable_search(self: PGtkDropDown): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_drop_down_get_enable_search';

procedure gtk4_drop_down_set_enable_search(self: PGtkDropDown;
  enable_search: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_drop_down_set_enable_search';

function gtk4_drop_down_get_show_arrow(self: PGtkDropDown): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_drop_down_get_show_arrow';

procedure gtk4_drop_down_set_show_arrow(self: PGtkDropDown;
  show_arrow: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_drop_down_set_show_arrow';

{ ---- GtkListView ---- }

function gtk4_list_view_new(model: PGtkSelectionModel;
  factory: PGtkListItemFactory): PGtkWidget; cdecl;
  external LazGtk4C_library name 'gtk_list_view_new';

function gtk4_list_view_get_model(self: PGtkListView): PGtkSelectionModel; cdecl;
  external LazGtk4C_library name 'gtk_list_view_get_model';

procedure gtk4_list_view_set_model(self: PGtkListView;
  model: PGtkSelectionModel); cdecl;
  external LazGtk4C_library name 'gtk_list_view_set_model';

function gtk4_list_view_get_factory(self: PGtkListView): PGtkListItemFactory; cdecl;
  external LazGtk4C_library name 'gtk_list_view_get_factory';

procedure gtk4_list_view_set_factory(self: PGtkListView;
  factory: PGtkListItemFactory); cdecl;
  external LazGtk4C_library name 'gtk_list_view_set_factory';

function gtk4_list_view_get_show_separators(self: PGtkListView): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_list_view_get_show_separators';

procedure gtk4_list_view_set_show_separators(self: PGtkListView;
  show_separators: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_list_view_set_show_separators';

function gtk4_list_view_get_single_click_activate(self: PGtkListView): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_list_view_get_single_click_activate';

procedure gtk4_list_view_set_single_click_activate(self: PGtkListView;
  single_click_activate: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_list_view_set_single_click_activate';

function gtk4_list_view_get_enable_rubberband(self: PGtkListView): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_list_view_get_enable_rubberband';

procedure gtk4_list_view_set_enable_rubberband(self: PGtkListView;
  enable_rubberband: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_list_view_set_enable_rubberband';

{ ---- GtkColumnView ---- }

function gtk4_column_view_new(model: PGtkSelectionModel): PGtkWidget; cdecl;
  external LazGtk4C_library name 'gtk_column_view_new';

function gtk4_column_view_get_model(self: PGtkColumnView): PGtkSelectionModel; cdecl;
  external LazGtk4C_library name 'gtk_column_view_get_model';

procedure gtk4_column_view_set_model(self: PGtkColumnView;
  model: PGtkSelectionModel); cdecl;
  external LazGtk4C_library name 'gtk_column_view_set_model';

function gtk4_column_view_get_columns(self: PGtkColumnView): PGListModel; cdecl;
  external LazGtk4C_library name 'gtk_column_view_get_columns';

procedure gtk4_column_view_append_column(self: PGtkColumnView;
  column: PGtkColumnViewColumn); cdecl;
  external LazGtk4C_library name 'gtk_column_view_append_column';

procedure gtk4_column_view_remove_column(self: PGtkColumnView;
  column: PGtkColumnViewColumn); cdecl;
  external LazGtk4C_library name 'gtk_column_view_remove_column';

procedure gtk4_column_view_insert_column(self: PGtkColumnView;
  position: guint; column: PGtkColumnViewColumn); cdecl;
  external LazGtk4C_library name 'gtk_column_view_insert_column';

function gtk4_column_view_get_sorter(self: PGtkColumnView): PGtkSorter; cdecl;
  external LazGtk4C_library name 'gtk_column_view_get_sorter';

procedure gtk4_column_view_sort_by_column(self: PGtkColumnView;
  column: PGtkColumnViewColumn; direction: TGtkSortType); cdecl;
  external LazGtk4C_library name 'gtk_column_view_sort_by_column';

function gtk4_column_view_get_show_row_separators(self: PGtkColumnView): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_column_view_get_show_row_separators';

procedure gtk4_column_view_set_show_row_separators(self: PGtkColumnView;
  show_row_separators: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_column_view_set_show_row_separators';

function gtk4_column_view_get_show_column_separators(self: PGtkColumnView): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_column_view_get_show_column_separators';

procedure gtk4_column_view_set_show_column_separators(self: PGtkColumnView;
  show_column_separators: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_column_view_set_show_column_separators';

function gtk4_column_view_get_single_click_activate(self: PGtkColumnView): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_column_view_get_single_click_activate';

procedure gtk4_column_view_set_single_click_activate(self: PGtkColumnView;
  single_click_activate: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_column_view_set_single_click_activate';

function gtk4_column_view_get_reorderable(self: PGtkColumnView): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_column_view_get_reorderable';

procedure gtk4_column_view_set_reorderable(self: PGtkColumnView;
  reorderable: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_column_view_set_reorderable';

function gtk4_column_view_get_enable_rubberband(self: PGtkColumnView): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_column_view_get_enable_rubberband';

procedure gtk4_column_view_set_enable_rubberband(self: PGtkColumnView;
  enable_rubberband: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_column_view_set_enable_rubberband';

{ ---- GtkColumnViewColumn ---- }

function gtk4_column_view_column_new(title: Pgchar;
  factory: PGtkListItemFactory): PGtkColumnViewColumn; cdecl;
  external LazGtk4C_library name 'gtk_column_view_column_new';

function gtk4_column_view_column_get_column_view(
  self: PGtkColumnViewColumn): PGtkColumnView; cdecl;
  external LazGtk4C_library name 'gtk_column_view_column_get_column_view';

function gtk4_column_view_column_get_title(self: PGtkColumnViewColumn): Pgchar; cdecl;
  external LazGtk4C_library name 'gtk_column_view_column_get_title';

procedure gtk4_column_view_column_set_title(self: PGtkColumnViewColumn;
  title: Pgchar); cdecl;
  external LazGtk4C_library name 'gtk_column_view_column_set_title';

function gtk4_column_view_column_get_factory(
  self: PGtkColumnViewColumn): PGtkListItemFactory; cdecl;
  external LazGtk4C_library name 'gtk_column_view_column_get_factory';

procedure gtk4_column_view_column_set_factory(self: PGtkColumnViewColumn;
  factory: PGtkListItemFactory); cdecl;
  external LazGtk4C_library name 'gtk_column_view_column_set_factory';

function gtk4_column_view_column_get_sorter(self: PGtkColumnViewColumn): PGtkSorter; cdecl;
  external LazGtk4C_library name 'gtk_column_view_column_get_sorter';

procedure gtk4_column_view_column_set_sorter(self: PGtkColumnViewColumn;
  sorter: PGtkSorter); cdecl;
  external LazGtk4C_library name 'gtk_column_view_column_set_sorter';

function gtk4_column_view_column_get_visible(self: PGtkColumnViewColumn): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_column_view_column_get_visible';

procedure gtk4_column_view_column_set_visible(self: PGtkColumnViewColumn;
  visible: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_column_view_column_set_visible';

function gtk4_column_view_column_get_expand(self: PGtkColumnViewColumn): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_column_view_column_get_expand';

procedure gtk4_column_view_column_set_expand(self: PGtkColumnViewColumn;
  expand: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_column_view_column_set_expand';

function gtk4_column_view_column_get_resizable(self: PGtkColumnViewColumn): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_column_view_column_get_resizable';

procedure gtk4_column_view_column_set_resizable(self: PGtkColumnViewColumn;
  resizable: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_column_view_column_set_resizable';

function gtk4_column_view_column_get_fixed_width(self: PGtkColumnViewColumn): gint; cdecl;
  external LazGtk4C_library name 'gtk_column_view_column_get_fixed_width';

procedure gtk4_column_view_column_set_fixed_width(self: PGtkColumnViewColumn;
  fixed_width: gint); cdecl;
  external LazGtk4C_library name 'gtk_column_view_column_set_fixed_width';

function gtk4_column_view_column_get_header_menu(
  self: PGtkColumnViewColumn): PGMenuModel; cdecl;
  external LazGtk4C_library name 'gtk_column_view_column_get_header_menu';

procedure gtk4_column_view_column_set_header_menu(self: PGtkColumnViewColumn;
  menu: PGMenuModel); cdecl;
  external LazGtk4C_library name 'gtk_column_view_column_set_header_menu';

{ ---- GtkGridView ---- }

function gtk4_grid_view_new(model: PGtkSelectionModel;
  factory: PGtkListItemFactory): PGtkWidget; cdecl;
  external LazGtk4C_library name 'gtk_grid_view_new';

function gtk4_grid_view_get_model(self: PGtkGridView): PGtkSelectionModel; cdecl;
  external LazGtk4C_library name 'gtk_grid_view_get_model';

procedure gtk4_grid_view_set_model(self: PGtkGridView;
  model: PGtkSelectionModel); cdecl;
  external LazGtk4C_library name 'gtk_grid_view_set_model';

function gtk4_grid_view_get_factory(self: PGtkGridView): PGtkListItemFactory; cdecl;
  external LazGtk4C_library name 'gtk_grid_view_get_factory';

procedure gtk4_grid_view_set_factory(self: PGtkGridView;
  factory: PGtkListItemFactory); cdecl;
  external LazGtk4C_library name 'gtk_grid_view_set_factory';

function gtk4_grid_view_get_min_columns(self: PGtkGridView): guint; cdecl;
  external LazGtk4C_library name 'gtk_grid_view_get_min_columns';

procedure gtk4_grid_view_set_min_columns(self: PGtkGridView;
  min_columns: guint); cdecl;
  external LazGtk4C_library name 'gtk_grid_view_set_min_columns';

function gtk4_grid_view_get_max_columns(self: PGtkGridView): guint; cdecl;
  external LazGtk4C_library name 'gtk_grid_view_get_max_columns';

procedure gtk4_grid_view_set_max_columns(self: PGtkGridView;
  max_columns: guint); cdecl;
  external LazGtk4C_library name 'gtk_grid_view_set_max_columns';

function gtk4_grid_view_get_enable_rubberband(self: PGtkGridView): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_grid_view_get_enable_rubberband';

procedure gtk4_grid_view_set_enable_rubberband(self: PGtkGridView;
  enable_rubberband: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_grid_view_set_enable_rubberband';

function gtk4_grid_view_get_single_click_activate(self: PGtkGridView): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_grid_view_get_single_click_activate';

procedure gtk4_grid_view_set_single_click_activate(self: PGtkGridView;
  single_click_activate: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_grid_view_set_single_click_activate';

{ ---- GtkCustomSorter ---- }

function gtk4_custom_sorter_new(sort_func: TGCompareDataFunc;
  user_data: gpointer; user_destroy: TGDestroyNotify): PGtkSorter; cdecl;
  external LazGtk4C_library name 'gtk_custom_sorter_new';

procedure gtk4_custom_sorter_set_sort_func(self: PGtkSorter;
  sort_func: TGCompareDataFunc; user_data: gpointer;
  user_destroy: TGDestroyNotify); cdecl;
  external LazGtk4C_library name 'gtk_custom_sorter_set_sort_func';

{ ---- GtkSorter (base class) ---- }

function gtk4_sorter_compare(self: PGtkSorter; item1: gpointer;
  item2: gpointer): TGtkOrdering; cdecl;
  external LazGtk4C_library name 'gtk_sorter_compare';

function gtk4_sorter_get_order(self: PGtkSorter): TGtkSorterOrder; cdecl;
  external LazGtk4C_library name 'gtk_sorter_get_order';

procedure gtk4_sorter_changed(self: PGtkSorter;
  change: TGtkSorterChange); cdecl;
  external LazGtk4C_library name 'gtk_sorter_changed';

{ ---- GtkFilter (base class) ---- }

function gtk4_filter_match(self: PGtkFilter; item: gpointer): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_filter_match';

function gtk4_filter_get_strictness(self: PGtkFilter): TGtkFilterMatch; cdecl;
  external LazGtk4C_library name 'gtk_filter_get_strictness';

procedure gtk4_filter_changed(self: PGtkFilter;
  change: TGtkFilterChange); cdecl;
  external LazGtk4C_library name 'gtk_filter_changed';

{ ---- GtkCustomFilter ---- }

function gtk4_custom_filter_new(match_func: TGtkCustomFilterFunc;
  user_data: gpointer; user_destroy: TGDestroyNotify): PGtkCustomFilter; cdecl;
  external LazGtk4C_library name 'gtk_custom_filter_new';

procedure gtk4_custom_filter_set_filter_func(self: PGtkCustomFilter;
  match_func: TGtkCustomFilterFunc; user_data: gpointer;
  user_destroy: TGDestroyNotify); cdecl;
  external LazGtk4C_library name 'gtk_custom_filter_set_filter_func';

{ ---- GtkFilterListModel ---- }

function gtk4_filter_list_model_new(model: PGListModel;
  filter: PGtkFilter): PGtkFilterListModel; cdecl;
  external LazGtk4C_library name 'gtk_filter_list_model_new';

procedure gtk4_filter_list_model_set_filter(self: PGtkFilterListModel;
  filter: PGtkFilter); cdecl;
  external LazGtk4C_library name 'gtk_filter_list_model_set_filter';

function gtk4_filter_list_model_get_filter(
  self: PGtkFilterListModel): PGtkFilter; cdecl;
  external LazGtk4C_library name 'gtk_filter_list_model_get_filter';

procedure gtk4_filter_list_model_set_model(self: PGtkFilterListModel;
  model: PGListModel); cdecl;
  external LazGtk4C_library name 'gtk_filter_list_model_set_model';

function gtk4_filter_list_model_get_model(
  self: PGtkFilterListModel): PGListModel; cdecl;
  external LazGtk4C_library name 'gtk_filter_list_model_get_model';

procedure gtk4_filter_list_model_set_incremental(
  self: PGtkFilterListModel; incremental: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_filter_list_model_set_incremental';

function gtk4_filter_list_model_get_incremental(
  self: PGtkFilterListModel): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_filter_list_model_get_incremental';

function gtk4_filter_list_model_get_pending(
  self: PGtkFilterListModel): guint; cdecl;
  external LazGtk4C_library name 'gtk_filter_list_model_get_pending';

{ ---- GtkSortListModel ---- }

function gtk4_sort_list_model_new(model: PGListModel;
  sorter: PGtkSorter): PGtkSortListModel; cdecl;
  external LazGtk4C_library name 'gtk_sort_list_model_new';

procedure gtk4_sort_list_model_set_sorter(self: PGtkSortListModel;
  sorter: PGtkSorter); cdecl;
  external LazGtk4C_library name 'gtk_sort_list_model_set_sorter';

function gtk4_sort_list_model_get_sorter(
  self: PGtkSortListModel): PGtkSorter; cdecl;
  external LazGtk4C_library name 'gtk_sort_list_model_get_sorter';

procedure gtk4_sort_list_model_set_model(self: PGtkSortListModel;
  model: PGListModel); cdecl;
  external LazGtk4C_library name 'gtk_sort_list_model_set_model';

function gtk4_sort_list_model_get_model(
  self: PGtkSortListModel): PGListModel; cdecl;
  external LazGtk4C_library name 'gtk_sort_list_model_get_model';

procedure gtk4_sort_list_model_set_incremental(self: PGtkSortListModel;
  incremental: gboolean); cdecl;
  external LazGtk4C_library name 'gtk_sort_list_model_set_incremental';

function gtk4_sort_list_model_get_incremental(
  self: PGtkSortListModel): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_sort_list_model_get_incremental';

function gtk4_sort_list_model_get_pending(
  self: PGtkSortListModel): guint; cdecl;
  external LazGtk4C_library name 'gtk_sort_list_model_get_pending';

{ ---- GdkToplevel state (GTK4: replaces gdk_window_get_state) ---- }

const
  GDK_TOPLEVEL_STATE_MINIMIZED  = 1;       { 1 shl 0 }
  GDK_TOPLEVEL_STATE_MAXIMIZED  = 2;       { 1 shl 1 }
  GDK_TOPLEVEL_STATE_STICKY     = 4;       { 1 shl 2 }
  GDK_TOPLEVEL_STATE_FULLSCREEN = 8;       { 1 shl 3 }
  GDK_TOPLEVEL_STATE_ABOVE      = 16;      { 1 shl 4 }
  GDK_TOPLEVEL_STATE_BELOW      = 32;      { 1 shl 5 }
  GDK_TOPLEVEL_STATE_FOCUSED    = 64;      { 1 shl 6 }
  GDK_TOPLEVEL_STATE_TILED      = 128;     { 1 shl 7 }

{ GTK4: GtkNative interface — get the GdkSurface for a native widget.
  GtkWindow and GtkPopover implement GtkNative. Parameter declared as
  PGtkWidget for convenience; callers must ensure the widget is a GtkNative.
  Returns PGdkWindow (which IS PGdkSurface in GTK4 — renamed type). }
function gtk4_native_get_surface(self: PGtkWidget): PGdkWindow; cdecl;
  external LazGtk4C_library name 'gtk_native_get_surface';

{ GTK4: Get the state flags for a GdkToplevel surface.
  Returns a bitmask of GDK_TOPLEVEL_STATE_* constants.
  Parameter uses PGdkWindow (= GTK4 GdkSurface); callers must ensure the
  surface is a GdkToplevel (i.e., it backs a toplevel GtkWindow). }
function gdk4_toplevel_get_state(toplevel: PGdkWindow): guint; cdecl;
  external LazGdk4_library name 'gdk_toplevel_get_state';

{ ---- GtkScrollbar (GTK4: no longer inherits from GtkRange) ---- }

{ GTK4 changed GtkScrollbar to inherit from GtkWidget directly, not GtkRange.
  The GTK3 binding TGtkScrollbar = object(TGtkRange) is incorrect for GTK4.
  Use these functions instead of PGtkRange cast + get_adjustment. }
function gtk4_scrollbar_get_adjustment(scrollbar: PGtkWidget): PGtkAdjustment; cdecl;
  external LazGtk4C_library name 'gtk_scrollbar_get_adjustment';
procedure gtk4_scrollbar_set_adjustment(scrollbar: PGtkWidget; adjustment: PGtkAdjustment); cdecl;
  external LazGtk4C_library name 'gtk_scrollbar_set_adjustment';

{ ---- GtkSpinButton (GTK4: no longer inherits from GtkEntry) ---- }

{ GTK4 changed GtkSpinButton to inherit from GtkWidget directly, not GtkEntry.
  The GTK3 binding TGtkSpinButton = object(TGtkEntry) is incorrect for GTK4.
  Use gtk_spin_button_get_adjustment and similar APIs instead of GtkEntry casts. }
function gtk4_spin_button_get_text(spin_button: PGtkWidget): Pgchar; cdecl;
  external LazGtk4C_library name 'gtk_editable_get_text';
procedure gtk4_spin_button_set_text(spin_button: PGtkWidget; text: Pgchar); cdecl;
  external LazGtk4C_library name 'gtk_editable_set_text';

{ ---- GtkFixedLayout vtable patch support (LCL-specific) ---- }

{ GTK4: gtk_widget_allocate is the native allocation function with GskTransform.
  Used by layout managers to position children. The 'transform' parameter
  encodes the child's position (e.g., translation from gtk_fixed_put).
  Unlike gtk_widget_size_allocate (which takes a GtkAllocation rect),
  this takes width, height, baseline, and a nullable GskTransform. }
procedure gtk4_widget_allocate(widget: PGtkWidget; width, height, baseline: gint;
  transform: PGskTransform); cdecl;
  external LazGtk4C_library name 'gtk_widget_allocate';

{ GTK4: Get the layout child metadata for a child widget from its layout manager }
function gtk4_layout_manager_get_layout_child(manager: Pointer;
  child: PGtkWidget): Pointer; cdecl;
  external LazGtk4C_library name 'gtk_layout_manager_get_layout_child';

{ GTK4: Get the position transform from a GtkFixedLayoutChild }
function gtk4_fixed_layout_child_get_transform(child: Pointer): PGskTransform; cdecl;
  external LazGtk4C_library name 'gtk_fixed_layout_child_get_transform';

{ GSK4: Reference-count a GskTransform (NULL-safe: returns NULL for NULL input) }
function gsk4_transform_ref(self: PGskTransform): PGskTransform; cdecl;
  external LazGtk4C_library name 'gsk_transform_ref';

{ GTK4: Check if widget should participate in layout (visible + non-native) }
function gtk4_widget_should_layout(widget: PGtkWidget): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_widget_should_layout';

{ GTK4: GType for GtkFixedLayout (the layout manager type, not the GtkFixed widget) }
function gtk4_fixed_layout_get_type: TGType; cdecl;
  external LazGtk4C_library name 'gtk_fixed_layout_get_type';

{ GSK4: Extract translation from a GskTransform.
  Returns TRUE if transform is a pure 2D translation, FALSE otherwise.
  out_dx/out_dy receive the translation offsets. }
function gsk4_transform_to_translate(self: PGskTransform;
  out_dx, out_dy: PSingle): gboolean; cdecl;
  external LazGtk4C_library name 'gsk_transform_to_translate';

{ ---- GdkToplevel compute-size (GTK4: replaces gtk_window_set_geometry_hints) ---- }

type
  { Opaque struct passed to the GdkToplevel::compute-size signal handler.
    Used to set size constraints for the toplevel window. }
  PGdkToplevelSize = Pointer;

{ Set the size the toplevel prefers to be resized to.
  The compositor may or may not respect this. }
procedure gdk_toplevel_size_set_size(size: PGdkToplevelSize;
  width, height: gint); cdecl;
  external LazGdk4_library name 'gdk_toplevel_size_set_size';

{ Set the minimum size of the toplevel. }
procedure gdk_toplevel_size_set_min_size(size: PGdkToplevelSize;
  min_width, min_height: gint); cdecl;
  external LazGdk4_library name 'gdk_toplevel_size_set_min_size';

{ Get the bounds the toplevel is placed within (e.g. monitor workarea). }
procedure gdk_toplevel_size_get_bounds(size: PGdkToplevelSize;
  out bounds_width, bounds_height: gint); cdecl;
  external LazGdk4_library name 'gdk_toplevel_size_get_bounds';

{ ---- GTK4 Accessible (new a11y system replacing ATK) ---- }

type
  { GtkAccessibleState — accessible state flags (tristate-aware) }
  TGtkAccessibleState = (
    GTK_ACCESSIBLE_STATE_BUSY,       // boolean
    GTK_ACCESSIBLE_STATE_CHECKED,    // tristate (true/false/mixed → GtkAccessibleTristate)
    GTK_ACCESSIBLE_STATE_DISABLED,   // boolean
    GTK_ACCESSIBLE_STATE_EXPANDED,   // boolean or undefined
    GTK_ACCESSIBLE_STATE_HIDDEN,     // boolean
    GTK_ACCESSIBLE_STATE_INVALID,    // GtkAccessibleInvalidState
    GTK_ACCESSIBLE_STATE_PRESSED,    // tristate
    GTK_ACCESSIBLE_STATE_SELECTED    // boolean or undefined
  );

  { GtkAccessibleProperty — accessible property values }
  TGtkAccessibleProperty = (
    GTK_ACCESSIBLE_PROPERTY_AUTOCOMPLETE,   // GtkAccessibleAutocomplete
    GTK_ACCESSIBLE_PROPERTY_DESCRIPTION,    // string
    GTK_ACCESSIBLE_PROPERTY_HAS_POPUP,      // boolean
    GTK_ACCESSIBLE_PROPERTY_KEY_SHORTCUTS,  // string
    GTK_ACCESSIBLE_PROPERTY_LABEL,          // string  *** KEY ***
    GTK_ACCESSIBLE_PROPERTY_LEVEL,          // int
    GTK_ACCESSIBLE_PROPERTY_MODAL,          // boolean
    GTK_ACCESSIBLE_PROPERTY_MULTI_LINE,     // boolean
    GTK_ACCESSIBLE_PROPERTY_MULTI_SELECTABLE, // boolean
    GTK_ACCESSIBLE_PROPERTY_ORIENTATION,    // GtkOrientation
    GTK_ACCESSIBLE_PROPERTY_PLACEHOLDER,    // string
    GTK_ACCESSIBLE_PROPERTY_READ_ONLY,      // boolean
    GTK_ACCESSIBLE_PROPERTY_REQUIRED,       // boolean
    GTK_ACCESSIBLE_PROPERTY_ROLE_DESCRIPTION, // string
    GTK_ACCESSIBLE_PROPERTY_SORT,           // GtkAccessibleSort
    GTK_ACCESSIBLE_PROPERTY_VALUE_MAX,      // double
    GTK_ACCESSIBLE_PROPERTY_VALUE_MIN,      // double
    GTK_ACCESSIBLE_PROPERTY_VALUE_NOW,      // double
    GTK_ACCESSIBLE_PROPERTY_VALUE_TEXT       // string
  );

  { GtkAccessibleRelation — accessible relations between widgets }
  TGtkAccessibleRelation = (
    GTK_ACCESSIBLE_RELATION_ACTIVE_DESCENDANT, // ref
    GTK_ACCESSIBLE_RELATION_COL_COUNT,         // int
    GTK_ACCESSIBLE_RELATION_COL_INDEX,         // int
    GTK_ACCESSIBLE_RELATION_COL_INDEX_TEXT,    // string
    GTK_ACCESSIBLE_RELATION_COL_SPAN,          // int
    GTK_ACCESSIBLE_RELATION_CONTROLS,          // ref list
    GTK_ACCESSIBLE_RELATION_DESCRIBED_BY,      // ref list
    GTK_ACCESSIBLE_RELATION_DETAILS,           // ref list
    GTK_ACCESSIBLE_RELATION_ERROR_MESSAGE,     // ref
    GTK_ACCESSIBLE_RELATION_FLOW_TO,           // ref list
    GTK_ACCESSIBLE_RELATION_LABELLED_BY,       // ref list  *** KEY ***
    GTK_ACCESSIBLE_RELATION_OWNS,              // ref list
    GTK_ACCESSIBLE_RELATION_POS_IN_SET,        // int
    GTK_ACCESSIBLE_RELATION_ROW_COUNT,         // int
    GTK_ACCESSIBLE_RELATION_ROW_INDEX,         // int
    GTK_ACCESSIBLE_RELATION_ROW_INDEX_TEXT,    // string
    GTK_ACCESSIBLE_RELATION_ROW_SPAN,          // int
    GTK_ACCESSIBLE_RELATION_SET_SIZE           // int
  );

  { GtkAccessibleTristate — for CHECKED/PRESSED states }
  TGtkAccessibleTristate = (
    GTK_ACCESSIBLE_TRISTATE_FALSE,
    GTK_ACCESSIBLE_TRISTATE_TRUE,
    GTK_ACCESSIBLE_TRISTATE_MIXED
  );

  { GtkAccessibleInvalidState — for INVALID state }
  TGtkAccessibleInvalidState = (
    GTK_ACCESSIBLE_INVALID_FALSE,
    GTK_ACCESSIBLE_INVALID_TRUE,
    GTK_ACCESSIBLE_INVALID_GRAMMAR,
    GTK_ACCESSIBLE_INVALID_SPELLING
  );

{ GTK4: Update accessible state using array of GValues (non-variadic).
  n_states: number of states to set
  states: array of state enum values
  values: array of GValues (pre-initialized with correct types) }
procedure gtk4_accessible_update_state_value(self: PGtkWidget;
  n_states: gint; states: Pointer; values: PGValue); cdecl;
  external LazGtk4C_library name 'gtk_accessible_update_state_value';

{ GTK4: Update accessible property using array of GValues (non-variadic). }
procedure gtk4_accessible_update_property_value(self: PGtkWidget;
  n_properties: gint; properties: Pointer; values: PGValue); cdecl;
  external LazGtk4C_library name 'gtk_accessible_update_property_value';

{ GTK4: Update accessible relation using array of GValues (non-variadic). }
procedure gtk4_accessible_update_relation_value(self: PGtkWidget;
  n_relations: gint; relations: Pointer; values: PGValue); cdecl;
  external LazGtk4C_library name 'gtk_accessible_update_relation_value';

{ GTK4: Reset an accessible state to its default value. }
procedure gtk4_accessible_reset_state(self: PGtkWidget;
  state: TGtkAccessibleState); cdecl;
  external LazGtk4C_library name 'gtk_accessible_reset_state';

{ GTK4: Reset an accessible property to its default value. }
procedure gtk4_accessible_reset_property(self: PGtkWidget;
  prop: TGtkAccessibleProperty); cdecl;
  external LazGtk4C_library name 'gtk_accessible_reset_property';

{ GTK4: Reset an accessible relation to its default value. }
procedure gtk4_accessible_reset_relation(self: PGtkWidget;
  rel: TGtkAccessibleRelation); cdecl;
  external LazGtk4C_library name 'gtk_accessible_reset_relation';

{ ---- GtkExpression (GTK4: functional-reactive property binding) ---- }

type
  PGtkExpressionWatch = Pointer; { Watch handle for expression evaluation }

{ Create a constant expression (wraps a GValue) }
function gtk4_constant_expression_new_for_value(value: PGValue): PGtkExpression; cdecl;
  external LazGtk4C_library name 'gtk_constant_expression_new_for_value';

{ Create a property expression (reads a property from another expression result) }
function gtk4_property_expression_new(this_type: TGType;
  expression: PGtkExpression; property_name: Pgchar): PGtkExpression; cdecl;
  external LazGtk4C_library name 'gtk_property_expression_new';

{ Create a closure expression (calls a GClosure with parameters) }
function gtk4_cclosure_expression_new(value_type: TGType;
  marshal: Pointer{GClosureMarshal}; n_params: guint;
  params: Pointer{PGtkExpression array}; callback_func: TGCallback;
  user_data: gpointer; user_destroy: TGDestroyNotify): PGtkExpression; cdecl;
  external LazGtk4C_library name 'gtk_cclosure_expression_new';

{ Evaluate an expression in the context of 'this' object }
function gtk4_expression_evaluate(self: PGtkExpression;
  this_: gpointer; value: PGValue): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_expression_evaluate';

{ Watch an expression for changes }
function gtk4_expression_watch(self: PGtkExpression; this_: gpointer;
  notify: TGCallback; user_data: gpointer;
  user_destroy: TGDestroyNotify): PGtkExpressionWatch; cdecl;
  external LazGtk4C_library name 'gtk_expression_watch';

{ Unwatch an expression }
procedure gtk4_expression_watch_unwatch(watch: PGtkExpressionWatch); cdecl;
  external LazGtk4C_library name 'gtk_expression_watch_unwatch';

{ Evaluate a watched expression }
function gtk4_expression_watch_evaluate(watch: PGtkExpressionWatch;
  value: PGValue): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_expression_watch_evaluate';

{ Reference counting for expressions }
function gtk4_expression_ref(self: PGtkExpression): PGtkExpression; cdecl;
  external LazGtk4C_library name 'gtk_expression_ref';

procedure gtk4_expression_unref(self: PGtkExpression); cdecl;
  external LazGtk4C_library name 'gtk_expression_unref';

{ Get the value type this expression evaluates to }
function gtk4_expression_get_value_type(self: PGtkExpression): TGType; cdecl;
  external LazGtk4C_library name 'gtk_expression_get_value_type';

{ Check if expression is static (never changes value) }
function gtk4_expression_is_static(self: PGtkExpression): gboolean; cdecl;
  external LazGtk4C_library name 'gtk_expression_is_static';

{ Bind an expression's value to a target object property }
function gtk4_expression_bind(self: PGtkExpression; target: gpointer;
  property_name: Pgchar; this_: gpointer): PGtkExpressionWatch; cdecl;
  external LazGtk4C_library name 'gtk_expression_bind';

implementation

end.
