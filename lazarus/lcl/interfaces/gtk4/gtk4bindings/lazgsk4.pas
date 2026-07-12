{ Minimal GSK4 binding stub for LCL GTK4 backend.
  GSK (GTK Scene Kit) is new in GTK4 and handles rendering.
  This stub provides only the essential types needed for compilation. }
unit LazGsk4;

{$MODE OBJFPC}{$H+}
{$PACKRECORDS C}

{$ifdef Unix}
{$LINKLIB libgtk-4.so.1}
{$endif}

interface

uses
  CTypes, LazGLib2, LazGObject2;

const
  {$ifdef MsWindows}
  LazGsk4_library = 'libgtk-4-1.dll';
  {$else}
  LazGsk4_library = 'libgtk-4.so.1';
  {$endif}

type
  { GskRenderNode - base type for scene graph nodes }
  PGskRenderNode = ^TGskRenderNode;
  TGskRenderNode = record
  end;

  { GskRenderer - renders a scene graph }
  PGskRenderer = ^TGskRenderer;
  TGskRenderer = object(TGObject)
  end;

  { GskTransform - transformation matrix }
  PGskTransform = ^TGskTransform;
  TGskTransform = record
  end;

  { GskRenderNodeType - enumeration of render node types }
  TGskRenderNodeType = Integer;

const
  GSK_NOT_A_RENDER_NODE = 0;
  GSK_CONTAINER_NODE = 1;
  GSK_CAIRO_NODE = 2;
  GSK_COLOR_NODE = 3;
  GSK_LINEAR_GRADIENT_NODE = 4;
  GSK_REPEATING_LINEAR_GRADIENT_NODE = 5;
  GSK_BORDER_NODE = 6;
  GSK_TEXTURE_NODE = 7;
  GSK_INSET_SHADOW_NODE = 8;
  GSK_OUTSET_SHADOW_NODE = 9;
  GSK_TRANSFORM_NODE = 10;
  GSK_OPACITY_NODE = 11;
  GSK_COLOR_MATRIX_NODE = 12;
  GSK_REPEAT_NODE = 13;
  GSK_CLIP_NODE = 14;
  GSK_ROUNDED_CLIP_NODE = 15;
  GSK_SHADOW_NODE = 16;
  GSK_BLEND_NODE = 17;
  GSK_CROSS_FADE_NODE = 18;
  GSK_TEXT_NODE = 19;
  GSK_BLUR_NODE = 20;
  GSK_DEBUG_NODE = 21;
  GSK_GL_SHADER_NODE = 22;

implementation

end.
