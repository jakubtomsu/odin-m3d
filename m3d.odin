package m3d

APIVERSION :: 0x0100

// Warning: changing any #config values apart from M3D_DEBUG requires a recompile of the C libs!

DOUBLE :: #config(M3D_DOUBLE, false)
Float :: f64 when DOUBLE else f32

SMALLINDEX :: #config(M3D_SMALLINDEX, false)
when !SMALLINDEX {
    Index :: u32
    Voxel_Data :: u16
    UNDEF :: 0xffffffff
    INDEXMAX :: 0xfffffffe
    VOXUNDEF :: 0xffff
    VOXCLEAR :: 0xfffe
} else {
    Index :: u16
    Voxel_Data :: u8
    UNDEF :: 0xffff
    INDEXMAX :: 0xfffe
    VOXUNDEF :: 0xff
    VOXCLEAR :: 0xfe
}

NOTDEFINED :: 0xffffffff

NUMBONE :: #config(MD3_NUMBONE, 4)
BONEMAXLEVEL :: #config(MD3_BONEMAXLEVEL, 64)

VERTEXTYPE :: #config(M3D_VERTEXTYPE, false)
ASCII :: #config(M3D_ASCII, false)
VERTEXMAX :: #config(M3D_VERTEXMAX, false)
CMDMAXARG :: #config(M3D_CMDMAXARG, 8) // if you increase this, add more arguments to the macro below

Hdr :: struct #packed {
    magic:  [4]u8,
    length: u32,
    scale:  f32, // deliberately not M3D_FLOAT
    types:  u32,
}

Chunk :: struct #packed {
    magic:  [4]u8,
    length: u32,
}

// ti_t: textmap entry
Texture_Index :: struct {
    u, v: Float,
}

// tx_t: texture
Texture_Data :: struct {
    name:   cstring, // texture name
    data:   [^]u8, // pixels data
    width:  u16, // width
    height: u16, // height
    format: Texture_Data_Format,
}

Texture_Data_Format :: enum u8 {
    Grayscale       = 1,
    Grayscale_Alpha = 2,
    Rgb             = 3,
    Rgba            = 4,
}

// w_t: Weight: weight
Weight :: struct {
    vertexid: Index,
    weight:   Float,
}

// b_t: bone entry
Bone :: struct {
    parent:    Index, // parent bone Index
    name:      cstring, // name for this bone
    pos:       Index, // vertex Index position
    ori:       Index, // vertex Index orientation (quaternion)
    numweight: Index, // number of controlled vertices
    weight:    [^]Weight, // weights for those vertices
    mat4:      matrix[4, 4]Float, // transformation matrix
}

// s_t: skin: bone per vertex entry
Skin :: struct {
    boneid: [NUMBONE]Index,
    weight: [NUMBONE]Float,
}

// v_t: vertex entry
Vertex :: struct {
    x:      Float, // 3D coordinates and weight
    y:      Float,
    z:      Float,
    w:      Float,
    color:  u32, // default vertex color
    skinid: Index, // skin Index
    type:   Vertex_Type,
}

Vertex_Type :: u8 when VERTEXTYPE else struct {}


// material property formats
Property_Format :: enum u8 {
    Color,
    Uint8,
    Uint16,
    Uint32,
    Float,
    Map,
}

// material property types
// You shouldn't change the first 8 display and first 4 physical property. Assign the rest as you like.
Property_Type :: enum u8 {
    Kd = 0, // scalar display properties
    Ka,
    Ks,
    Ns,
    Ke,
    Tf,
    Km,
    D,
    Il,
    Pr = 64, // scalar physical properties
    Pm,
    Ps,
    Ni,
    Nt,
    Map_Kd = 128, // textured display map properties
    Map_Ka,
    Map_Ks,
    Map_Ns,
    Map_Ke,
    Map_Tf,
    Map_Km, // bump map
    Map_D,
    Map_N, // normal map
    Map_Pr = 192, // textured physical map properties
    Map_Pm,
    Map_Ps,
    Map_Ni,
    Map_Nt,
    // aliases
    Bump = Map_Km,
    Map_Il = Map_N,
    Refl = Map_Pm,
}

// p_t: material property
Property :: struct {
    type:  Property_Type, // property type, see "m3dp_*" enumeration
    value: struct #raw_union {
        color:     u32, // if value is a color, Property_Format.Color
        num:       u32, // if value is a number, Property_Format.Uint8, Property_Format.Uint16, Property_Format.Uint32
        fnum:      f32, // if value is a floating point number, Property_Format.Float
        textureid: Index, // if value is a texture, Property_Format.Map
    },
}

// m_t: material entry
Material :: struct {
    name:    cstring, // name of the material
    numprop: u8, // number of properties
    prop:    [^]Property, // properties array
}

// f_t: face entry
Face :: struct {
    materialid:      Index, // material Index
    vertex:          [3]Index, // 3D points of the triangle in CCW order
    normal:          [3]Index, // normal vectors
    texcoord:        [3]Index, // UV coordinates
    using vertexmax: Face_Vertexmax,
}

when VERTEXMAX {
    Face_Vertexmax :: struct {
        paramid: Index, // parameter Index
        vertmax: [3]Index, // maximum 3D points of the triangle in CCW order
    }
} else {
    Face_Vertexmax :: struct {}
}

// vi_t
Voxel_Item :: struct {
    count: u16,
    name:  cstring,
}

// vt_t: voxel types (voxel palette)
Voxel_Type :: struct {
    name:       cstring, // technical name of the voxel
    rotation:   u8, // rotation info
    voxshape:   u16, // voxel shape
    materialid: Index, // material Index
    color:      u32, // default voxel color
    skinid:     Index, // skin Index
    numitem:    u8, // number of sub-voxels
    item:       [^]Voxel_Item, // list of sub-voxels
}

// vx_t: voxel data blocks
Voxel :: struct {
    name:      cstring, // name of the block
    x, y, z:   i32, // position
    w, h, d:   u32, // dimension
    uncertain: u8, // probability
    groupid:   u8, // block group id
    data:      [^]Voxel_Data, // voxel data, indices to voxel type
}

// c_t: shape command
Shape_Command :: struct {
    type: Shape_Command_Type, // shape type
    arg:  [^]Shape_Command_Argument_Type, // arguments array
}

// shape command types. must match the row in m3d_commandtypes
Shape_Command_Type :: enum u16 {
    // special commands
    Use = 0, // use material
    Inc, // include another shape
    Mesh, // include part of polygon mesh
    // approximations
    Div, // subdivision by constant resolution for both u, v
    Sub, // subdivision by constant, different for u and v
    Len, // spacial subdivision by maxlength
    Dist, // subdivision by maxdistance and maxangle
    // modifiers
    Degu, // degree for both u, v
    Deg, // separate degree for u and v
    Rangeu, // range for u
    Range, // range for u and v
    Paru, // u parameters (knots)
    Parv, // v parameters
    Trim, // outer trimming curve
    Hole, // inner trimming curve
    Scrv, // spacial curve
    Sp, // special points
    // helper curves
    Bez1, // Bezier 1D
    Bsp1, // B-spline 1D
    Bez2, // bezier 2D
    Bsp2, // B-spline 2D
    // surfaces
    Bezun, // Bezier 3D with control, UV, normal
    Bezu, // with control and UV
    Bezn, // with control and normal
    Bez, // control points only
    Nurbsun, // B-spline 3D
    Nurbsu,
    Nurbsn,
    Nurbs,
    Conn, // connect surfaces
    // geometrical
    Line,
    Polygon,
    Circle,
    Cylinder,
    Shpere,
    Torus,
    Cone,
    Cube,
}

// shape command argument types
Shape_Command_Argument_Type :: enum u32 {
    Material_Index = 1, // mi
    Shape_Index, // hi
    Face_Index, // fi
    Texture_Map_Index, // ti
    Vertex_Index, // vi
    Vertex_Index_For_Quaternions, // qi
    Float_Scalar, // vc - coordinate or radius
    Int8_Scalar, // i1
    Int16_Scalar, // i2
    Int32_Scalar, // i4
    Variadic_Arguments, // v
}

// h_t: shape entry
Shape :: struct {
    name:   cstring, // name of the mathematical shape
    group:  Index, // group this shape belongs to or -1
    numcmd: u32, // number of commands
    cmd:    [^]Shape_Command, // commands array
}

// l_t: label entry
Label :: struct {
    name:     cstring, // name of the annotation layer or NULL
    lang:     cstring, // language code or NULL
    text:     cstring, // the label text
    color:    u32, // color
    vertexid: Index, // the vertex the label refers to
}

// dtr_t: frame transformations / working copy skeleton entry
Transform :: struct {
    boneid: Index, // selects a node in bone hierarchy
    pos:    Index, // vertex Index new position
    ori:    Index, // vertex Index new orientation (quaternion)
}

// fr_t: animation frame entry
Frame :: struct {
    msec:         u32, // frame's position on the timeline, timestamp
    numtransform: Index, // number of transformations in this frame
    transform:    [^]Transform, // transformations
}

// da_t: model action entry
Action :: struct {
    name:         cstring, // name of the action
    durationmsec: u32, // duration in millisec (1/1000 sec)
    numframe:     Index, // number of frames in this animation
    frame:        [^]Frame, // frames array
}

// di_t: inlined asset
Inlined_Asset :: struct {
    name:   cstring, // asset name (same pointer as in texture[].name)
    data:   [^]u8, // compressed asset data
    length: u32, // compressed data length
}

// in-memory model structure
Flag :: enum u8 {
    Freeraw,
    Freestr,
    Mtllib,
    Gennorm,
}

when VERTEXMAX {
    M3d_Vertexmax :: struct {
        numparam: Index,
        param:    [^]Voxel_Item, // parameters and their values list
    }
} else {
    M3d_Vertexmax :: struct {}
}

Error :: enum i8 {
    Success  = 0,
    Alloc    = -1,
    Badfile  = -2,
    Unimpl   = -65,
    Unkprop  = -66,
    Unkmesh  = -67,
    Unkimg   = -68,
    Unkframe = -69,
    Unkcmd   = -70,
    Unkvox   = -71,
    Trunc    = -72,
    Cmap     = -73,
    Tmap     = -74,
    Vrts     = -75,
    Bone     = -76,
    Mtrl     = -77,
    Shpe     = -78,
    Voxt     = -79,
}

M3d :: struct {
    raw:                                                                          ^Hdr, // pointer to raw data
    flags:                                                                        bit_set[Flag], // internal flags
    errcode:                                                                      Error, // returned error code
    vc_s, vi_s, si_s, ci_s, ti_s, bi_s, nb_s, sk_s, fc_s, hi_s, fi_s, vd_s, vp_s: u8, // decoded sizes for types
    name:                                                                         cstring, // name of the model, like "Utah teapot"
    license:                                                                      cstring, // usage condition or license, like "MIT", "LGPL" or "BSD-3clause"
    author:                                                                       cstring, // nickname, email, homepage or github URL etc.
    desc:                                                                         cstring, // comments, descriptions. May contain '\n' newline character
    scale:                                                                        Float, // the model's bounding cube's size in SI meters
    numcmap:                                                                      Index,
    cmap:                                                                         [^]u32, // color map
    numtmap:                                                                      Index,
    tmap:                                                                         [^]Texture_Index, // texture map indices
    numtexture:                                                                   Index,
    texture:                                                                      [^]Texture_Data, // uncompressed textures
    numbone:                                                                      Index,
    bone:                                                                         [^]Bone, // bone hierarchy
    numvertex:                                                                    Index,
    vertex:                                                                       [^]Vertex, // vertex data
    numskin:                                                                      Index,
    skin:                                                                         [^]Skin, // skin data
    nummaterial:                                                                  Index,
    material:                                                                     [^]Material, // material list
    using vertexmax:                                                              M3d_Vertexmax,
    numface:                                                                      Index,
    face:                                                                         [^]Face, // model face, polygon (triangle) mesh
    numvoxtype:                                                                   Index,
    voxtype:                                                                      [^]Voxel_Type, // model face, voxel types
    numvoxel:                                                                     Index,
    voxel:                                                                        [^]Voxel, // model face, cubes compressed into voxels
    numshape:                                                                     Index,
    shape:                                                                        [^]Shape, // model face, shape commands
    numlabel:                                                                     Index,
    label:                                                                        [^]Label, // annotation labels
    numaction:                                                                    Index,
    action:                                                                       [^]Action, // action animations
    numinlined:                                                                   Index,
    inlined:                                                                      [^]Inlined_Asset, // inlined assets
    numextra:                                                                     Index,
    extra:                                                                        [^]^Chunk, // unknown chunks, application / engine specific data probably
    preview:                                                                      Inlined_Asset, // preview chunk
}

// read file contents into buffer
Read_Proc :: #type proc "c" (filename: cstring, size: ^u32) -> [^]u8

// free file contents buffer
Free_Proc :: #type proc "c" (buffer: rawptr)

// interpret texture script
Texture_Script_Proc :: #type proc "c" (name: cstring, script: rawptr, len: u32, output: ^Texture_Data) -> i32

// interpret surface script
Surface_Script_Proc :: #type proc "c" (name: cstring, script: rawptr, len: u32, model: ^M3d) -> i32

DEBUG :: #config(M3D_DEBUG, ODIN_DEBUG)

when ODIN_OS == .Windows {
    when DEBUG {
        foreign import lib "m3d_windows_debug.lib"
    } else {
        foreign import lib "m3d_windows_release.lib"
    }
} else {
    #panic("Current OS not supported")
}

@(default_calling_convention = "c", link_prefix = "m3d_")
foreign lib {
    @(require_results)
    load :: proc(data: [^]u8, readfilecb: Read_Proc, freecb: Free_Proc, mtllib: ^M3d) -> ^M3d ---
    @(require_results)
    save :: proc(model: ^M3d, quality, flags: i32, size: ^u32) -> [^]u8 ---
    free :: proc(model: ^M3d) ---
    // generate animation pose skeleton
    @(require_results)
    frame :: proc(model: ^M3d, actionid: Index, frameid: Index, skeleton: ^Transform) -> ^Transform ---
    @(require_results)
    pose :: proc(model: ^M3d, actionid: Index, msec: u32) -> ^Bone ---
    // private prototypes used by both importer and exporter
    _m3d_safestr :: proc(in_: cstring, morelines: i32) -> cstring ---
}
