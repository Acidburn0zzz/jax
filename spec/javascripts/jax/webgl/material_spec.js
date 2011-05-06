describe("Jax.Material", function() {
  var material, context, mesh;
  var _img = "/public/images/rss.png";
  
  beforeEach(function() { mesh = new Jax.Mesh(); context = new Jax.Context('canvas-element'); });
  afterEach(function() { context.dispose(); });

  describe("with one texture specified by string", function() {
    beforeEach(function() { material = new Jax.Material({texture: _img}); });
    it("should have texture layer", function() {
      expect(material.layers[0].texture.image.src).toMatch(/\/public\/images\/rss\.png$/);
    });
  });
  
  describe("with multiple textures specified by string", function() {
    beforeEach(function() { material = new Jax.Material({textures: [_img, _img]}); });
    
    it("should have 2 texture layers", function() {
      expect(material.layers[0].texture.image.src).toMatch(/\/public\/images\/rss\.png$/);
      expect(material.layers[1].texture.image.src).toMatch(/\/public\/images\/rss\.png$/);
    });
  });
  
  describe("with a normal map", function() {
    beforeEach(function() { material = new Jax.Material({texture:{path:_img,type:Jax.NORMAL_MAP}}); });
    it("should use Jax.Material.NormalMap", function() {
      expect(material.layers[0]).toBeKindOf(Jax.Material.NormalMap);
    });
  });
  
  describe("by default", function() {
    beforeEach(function() { material = new Jax.Material(); });

    describe("switching shaders", function() {
      it("should not rebuild the shaders", function() {
        material.render(context, mesh, {shader:"basic"});
        material.render(context, mesh, {shader:"blinn-phong"});
        
        spyOn(material, 'buildShader').andCallThrough();
        material.render(context, mesh, {shader:"basic"});
        expect(material.buildShader).not.toHaveBeenCalled();
      });
      
//      it("should build both shaders", function() {
//        spyOn(material, 'buildShader').andCallThrough();
//        material.render(context, mesh, {shader:"blinn-phong"});
//        material.render(context, mesh, {shader:"basic"});
//        expect(material.buildShader).toHaveBeenCalledWith('blinn-phong', context);
//        expect(material.buildShader).toHaveBeenCalledWith('basic', context);
//      });
    });
  
    
//    it("should use basic shader", function() {
//      spyOn(material, 'prepareShader').andCallThrough();
//      material.render(context, mesh);
//      // I don't like this, but I don't know a better way to test it.
//      expect(material.prepareShader).toHaveBeenCalledWith('basic', context);
//    });
  });

  it("should have a default material", function() {
    expect(Jax.Material.find('default')).not.toBeUndefined();
  });
});
