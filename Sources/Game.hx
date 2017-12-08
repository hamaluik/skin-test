import kha.System;
import kha.Framebuffer;
import kha.Color;
import kha.Shaders;
import kha.Image;
import kha.Assets;
import kha.graphics4.PipelineState;
import kha.graphics4.VertexStructure;
import kha.graphics4.VertexData;
import kha.graphics4.ConstantLocation;
import kha.graphics4.TextureUnit;
import kha.graphics4.CullMode;
import kha.graphics4.CompareMode;
import kha.graphics4.VertexStructure;
import kha.graphics4.VertexBuffer;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Usage;
import haxe.ds.Vector;
import gltf.GLTF;
import glm.GLM;
using glm.Mat4;
using glm.Vec4;
using glm.Vec3;
using glm.Quat;

@:allow(Main)
class Game {
	static var pipeline:PipelineState;
	static var mvpID:ConstantLocation;
    static var texID:TextureUnit;

    static var mvp:Mat4;

    static var vertexBuffer:VertexBuffer;
	static var indexBuffer:IndexBuffer;

    static function initialize():Void {
        var structure = new VertexStructure();
        structure.add("position", VertexData.Float3);
        structure.add("texcoord", VertexData.Float2);

		pipeline = new PipelineState();
		pipeline.inputLayout = [structure];
		pipeline.vertexShader = Shaders.skin_vert;
		pipeline.fragmentShader = Shaders.skin_frag;
        pipeline.cullMode = CullMode.Clockwise;
        pipeline.depthMode = CompareMode.Less;
        pipeline.depthWrite = true;

        try {
            pipeline.compile();
        }
        catch(e:String) {
            #if js
            js.Browser.console.error(e);
            #else
            trace('ERROR:');
            trace(e);
            #end
        }

		mvpID = pipeline.getConstantLocation("MVP");
		texID = pipeline.getTextureUnit("tex");

        var cylinder:GLTF = GLTF.parseAndLoad(Assets.blobs.cylinder_gltf.toString(), [
            Assets.blobs.cylinder_bin.bytes
        ]);

        var positions:Vector<Float> = cylinder.meshes[0].primitives[0].getFloatAttributeValues("POSITION");
        var texcoords:Vector<Float> = cylinder.meshes[0].primitives[0].getFloatAttributeValues("TEXCOORD_0");
        var indices:Vector<Int> = cylinder.meshes[0].primitives[0].getIndexValues();

        var numVerts:Int = Std.int(positions.length / 3);

        vertexBuffer = new VertexBuffer(numVerts, structure, Usage.StaticUsage);
        var vbData = vertexBuffer.lock();
        for(v in 0...numVerts) {
            vbData[(v * 5) + 0] = positions[(v * 3) + 0];
            vbData[(v * 5) + 1] = positions[(v * 3) + 1];
            vbData[(v * 5) + 2] = positions[(v * 3) + 2];

            vbData[(v * 5) + 3] = texcoords[(v * 2) + 0];
            vbData[(v * 5) + 4] = texcoords[(v * 2) + 1];
        }
        vertexBuffer.unlock();

		indexBuffer = new IndexBuffer(indices.length, Usage.StaticUsage);
		var iData = indexBuffer.lock();
		for (i in 0...iData.length) {
			iData[i] = indices[i];
		}
		indexBuffer.unlock();

        mvp = new Mat4();
        var m = Mat4.identity(new Mat4());
        var v:Mat4 = GLM.lookAt(
            new Vec3(5, 5, 5),
            new Vec3(0, 0, 0),
            new Vec3(0, 1, 0),
            new Mat4()
        );
        var p:Mat4 = GLM.perspective(
            49 * Math.PI / 180,
            System.windowWidth() / System.windowHeight(),
            0.1, 100,
            new Mat4()
        );
        var vp = Mat4.multMat(p, v, new Mat4());
        mvp = Mat4.multMat(vp, m, mvp);
    }

    static function update():Void {
    }

    static function render(fb:Framebuffer):Void {
        var g = fb.g4;

        g.begin();
        g.clear(Color.Black, 1);
        g.setPipeline(pipeline);

        g.setMatrix(mvpID, mvp);
        g.setTexture(texID, Assets.images.uvgrid);

        g.setVertexBuffer(vertexBuffer);
        g.setIndexBuffer(indexBuffer);
        g.drawIndexedVertices();
    }
}
