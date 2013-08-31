#= require jax/mixins/attributes
#= require jax/mixins/event_emitter
#= require_self
#= require_tree ./texture

###

The base class for all textures in Jax. Usually, you want one of the
subclasses of `Jax.Texture` instead.

The base class can be useful if you have a special one-off use case, but it
is probably a better idea to go ahead and subclass `Jax.Texture` anyway.

If you are sure you need to instantiate `Jax.Texture` directly, then you
will need to provide an `upload` option. This should be a function, which
will replace the default `upload` method defined by this class.

Note that providing an `upload` method is required if you instantiate
`Jax.Texture` directly, because the default implementation will simply
throw an error.

See the documentation for the `upload` method for implementation details.

###
class Jax.Texture
  @include Jax.Mixins.Attributes
  @include Jax.Mixins.EventEmitter

  # Texture params flags, for tracking params needing refreshed
  FLAGS =
    texture_validity:      0x0001
    min_filter:            0x0002
    mag_filter:            0x0004
    generate_mipmap:       0x0008
    mipmap_hint:           0x0010
    format:                0x0020
    target:                0x0040
    data_type:             0x0080
    wrap_s:                0x0100
    wrap_t:                0x0200
    flip_y:                0x0400
    premultiply_alpha:     0x0800
    colorspace_conversion: 0x1000
    data:                  0x2000

  constructor: (options) ->
    @initializeAttributes()
    @upload = options.upload if options?.upload
    @on 'change:width change:height', @sizeChanged
    @on 'change:min_filter              change:mag_filter
         change:generate_mipmap         change:mipmap_hint
         change:format                  change:target
         change:date_type               change:wrap_s
         change:wrap_t change:flip_y    change:premultiply_alpha
         change:colorspace_conversion   change:data',
         @texParamChanged
    @set 'handles',               {}
    @set 'min_filter',            GL_NEAREST
    @set 'mag_filter',            GL_NEAREST
    @set 'generate_mipmap',       true
    @set 'mipmap_hint',           GL_DONT_CARE
    @set 'format',                GL_RGBA
    @set 'target',                GL_TEXTURE_2D
    @set 'data_type',             GL_UNSIGNED_BYTE
    @set 'wrap_s',                GL_REPEAT
    @set 'wrap_t',                GL_REPEAT
    @set 'flip_y',                false
    @set 'premultiply_alpha',     false
    @set 'colorspace_conversion', true
    @set 'width',                 1
    @set 'height',                1
    @set 'data',                  null
    for option, value of options
      @set option, value
    true

  ###
  Callback which is fired whenever a texture parameter changes which must
  be reflected within a renderer. This method causes the texture to become
  invalid, and also makes a note as to which parameters must be refreshed.
  ###
  texParamChanged: (self, evtName) =>
    flags = @get('changedTexParams') || 0
    param = evtName.substring(evtName.indexOf('change:')+7, evtName.length)
    @set 'changedTexParams', flags | FLAGS.texture_validity | FLAGS[param]

  ###
  Finds or creates and then returns the texture handle for the given context.
  ###
  getHandle: (context) ->
    handle = @get('handles')[context.id] or= context.renderer.createTexture()

  ###
  Deletes the texture handle associated with the specified context. This
  method is responsible for performing any and all shutdown related to this
  texture.
  ###
  dispose: (context) ->
    handles = @get('handles')
    context.renderer.deleteTexture handles[context.id] if handles[context.id]
    handles[context.id] = null

  ###
  Returns true if this texture is valid for rendering, false otherwise.
  Changes to the texture which have not been correlated within the renderer
  will cause it to be invalid. Textures are invalid by default. They become
  valid automatically when they are bound to a graphics driver.
  ###
  isValid: -> @get 'changedTexParams' & FLAGS.texture_validity

  ###
  Forces this texture to become valid, even if the latest changes have not
  been reflected within the graphics driver.
  ###
  forceValid: -> @set 'flags', 0

  ###
  Subclasses must implement this method. It is called during validation,
  whenever the `data` attribute changes. It receives the context and the
  texture handle. Subclasses should use this method to upload texture data
  to the renderer.
  ###
  upload: (context, handle, textureData) ->
    throw new Error "Do not use Jax.Texture directly, use a subclass instead"

  ###
  Subclasses should implement this method. Its function is to check whether
  the underlying texture data is ready to be used. For example, a texture that
  is loaded from a remote resource would return `false` until the resource has
  been loaded, `true` afterward.

  The default implementation always returns true.
  ###
  isReady: -> true

  ###
  Ensures that the texture handle exists for the given context, and verifies
  that the texture is valid for rendering. If it is not, this method takes
  the necessary steps to make the texture valid.

  If `isReady` returns false, this method has no effect and returns `false`.
  ###
  validate: (context) ->
    return false unless @isReady()
    handle = @getHandle context
    flags = @get 'changedTexParams'
    return handle unless flags & FLAGS.texture_validity
    # texture is not valid, make it so!
    target = @get 'target'
    gl = context.renderer
    gl.bindTexture target, handle
    if flags & FLAGS.data or flags & FLAGS.format or flags & FLAGS.data_type or
       flags & FLAGS.target
      @upload context, handle, @get 'data'
    gl.texParameteri target, GL_TEXTURE_MAG_FILTER, @get 'mag_filter' if flags & FLAGS.mag_filter
    gl.texParameteri target, GL_TEXTURE_MIN_FILTER, @get 'min_filter' if flags & FLAGS.min_filter
    gl.texParameteri target, GL_TEXTURE_WRAP_S,     @get 'wrap_s'     if flags & FLAGS.wrap_s
    gl.texParameteri target, GL_TEXTURE_WRAP_T,     @get 'wrap_t'     if flags & FLAGS.wrap_t
    gl.pixelStorei GL_UNPACK_FLIP_Y_WEBGL, @get 'flip_y'              if flags & FLAGS.flip_y
    gl.pixelStorei GL_UNPACK_PREMULTIPLY_ALPHA_WEBGL, @get 'premultiply_alpha' if flags & FLAGS.premultiply_alpha
    if flags & FLAGS.colorspace_conversion
      conversion = if @get('colorspace_conversion') then GL_BROWSER_DEFAULT_WEBGL else GL_NONE
      gl.pixelStorei GL_UNPACK_COLORSPACE_CONVERSION_WEBGL, conversion
    if @get 'generate_mipmap'
      @generateMipmap gl, target, @get 'mipmap_hint'
    # done!
    @set 'changedTexParams', 0
    return handle

  generateMipmap: (renderer, target, hint) ->
    # FIXME why does this raise 1280 invalid enum?
    # renderer.hint GL_GENERATE_MIPMAP_HINT, hint
    renderer.generateMipmap target

  ###
  Callback which is fired whenever the `width` or `height` attribute changes.
  If either is a non-power-of-two value, this texture's other attributes will
  be set to compatibility values in order to make the texture renderable.
  Otherwise, they are left unchanged.
  ###
  sizeChanged: =>
    if Jax.Util.isPowerOfTwo(@get 'width') and
       Jax.Util.isPowerOfTwo(@get 'height')
      @isPoT = true
    else
      if @isPoT
        @set 'min_filter', GL_LINEAR
        @set 'mag_filter', GL_LINEAR
        @set 'wrap_s', GL_CLAMP_TO_EDGE
        @set 'wrap_t', GL_CLAMP_TO_EDGE
        @set 'generate_mipmap', false
      @isPoT = false
