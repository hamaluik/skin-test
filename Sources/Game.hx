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
import kha.graphics4.TextureAddressing;
import kha.graphics4.TextureFilter;
import kha.graphics4.MipMapFilter;
import haxe.ds.Vector;
import gltf.GLTF;
import glm.GLM;
import glm.Mat4;
import glm.Vec4;
import glm.Vec3;
import glm.Quat;

@:allow(Main)
class Game {
	static var pipeline:PipelineState;
	static var mvpID:ConstantLocation;
    static var jointMatricesIDs:Array<ConstantLocation>;
    static var texID:TextureUnit;
    static var inverseBindMatrices:Array<Mat4>;

    static var mvp:Mat4;
    static var vp:Mat4;
    static var mBase:Mat4;
    static var mJoints:Array<Mat4>;

    static var jointMatrices:Array<Mat4>;

    static var vertexBuffer:VertexBuffer;
	static var indexBuffer:IndexBuffer;

    static var angle:Float = 0;

    static function initialize():Void {
        var structure = new VertexStructure();
        structure.add("position", VertexData.Float3);
        structure.add("texcoord", VertexData.Float2);
        structure.add("joints", VertexData.Float4);
        structure.add("weights", VertexData.Float4);

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
        jointMatricesIDs = new Array<ConstantLocation>();
        jointMatricesIDs.push(pipeline.getConstantLocation("jointMatrices[0]"));
        jointMatricesIDs.push(pipeline.getConstantLocation("jointMatrices[1]"));
		texID = pipeline.getTextureUnit("tex");

        var cylinder:GLTF = GLTF.parseAndLoad(Assets.blobs.cylinder_gltf.toString(), [
            Assets.blobs.cylinder_bin.bytes
        ]);

        var positions:Vector<Float> = cylinder.meshes[0].primitives[0].getFloatAttributeValues("POSITION");
        var texcoords:Vector<Float> = cylinder.meshes[0].primitives[0].getFloatAttributeValues("TEXCOORD_0");
        var joints:Vector<Int> = cylinder.meshes[0].primitives[0].getIntAttributeValues("JOINTS_0");
        var weights:Vector<Float> = cylinder.meshes[0].primitives[0].getFloatAttributeValues("WEIGHTS_0");
        var indices:Vector<Int> = cylinder.meshes[0].primitives[0].getIndexValues();

        var numVerts:Int = Std.int(positions.length / 3);

        vertexBuffer = new VertexBuffer(numVerts, structure, Usage.StaticUsage);
        var vbData = vertexBuffer.lock();
        for(v in 0...numVerts) {
            vbData[(v * 13) + 0] = positions[(v * 3) + 0];
            vbData[(v * 13) + 1] = positions[(v * 3) + 1];
            vbData[(v * 13) + 2] = positions[(v * 3) + 2];

            vbData[(v * 13) + 3] = texcoords[(v * 2) + 0];
            vbData[(v * 13) + 4] = texcoords[(v * 2) + 1];

            vbData[(v * 13) + 5] = joints[(v * 4) + 0];
            vbData[(v * 13) + 6] = joints[(v * 4) + 1];
            vbData[(v * 13) + 7] = joints[(v * 4) + 2];
            vbData[(v * 13) + 8] = joints[(v * 4) + 3];

            vbData[(v * 13) +  9] = weights[(v * 4) + 0];
            vbData[(v * 13) + 10] = weights[(v * 4) + 1];
            vbData[(v * 13) + 11] = weights[(v * 4) + 2];
            vbData[(v * 13) + 12] = weights[(v * 4) + 3];
        }
        vertexBuffer.unlock();

		indexBuffer = new IndexBuffer(indices.length, Usage.StaticUsage);
		var iData = indexBuffer.lock();
		for (i in 0...iData.length) {
			iData[i] = indices[i];
		}
		indexBuffer.unlock();

        mvp = new Mat4();
        mBase = Mat4.identity(new Mat4());
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
        vp = Mat4.multMat(p, v, new Mat4());

        inverseBindMatrices = new Array<Mat4>();
        inverseBindMatrices.push(Mat4.fromFloatArray(cylinder.skins[0].inverseBindMatrices[0].toArray()));
        inverseBindMatrices.push(Mat4.fromFloatArray(cylinder.skins[0].inverseBindMatrices[1].toArray()));

        mJoints = new Array<Mat4>();
        mJoints.push(Mat4.identity(new Mat4()));
        mJoints.push(Mat4.identity(new Mat4()));
        GLM.translate(new Vec3(0, 1, 0), mJoints[1]);

        jointMatrices = new Array<Mat4>();
        jointMatrices.push(Mat4.identity(new Mat4()));
        jointMatrices.push(Mat4.identity(new Mat4()));
    }

    static function update():Void {
        // TODO: base movement isn't being applied?
        GLM.translate(new Vec3(Math.cos(angle), -1, Math.sin(angle)), mBase);
        GLM.transform(
            new Vec3(0, 1, 0),
            Quat.fromEuler(0, Math.sin(angle) * Math.PI / 2, 0, new Quat()),
            new Vec3(1, 1, 1),
            mJoints[1]
        );
        angle += (Math.PI / 2) / 60;

        var mInverse:Mat4 = Mat4.invert(mBase, new Mat4());
        for(i in 0...2) {
            Mat4.multMat(mInverse, mJoints[i], jointMatrices[i]);
            Mat4.multMat(jointMatrices[i], inverseBindMatrices[i], jointMatrices[i]);
        }

        Mat4.multMat(vp, mBase, mvp);
    }

    static function render(fb:Framebuffer):Void {
        var g = fb.g4;

        g.begin();
        g.clear(Color.Black, 1);
        g.setPipeline(pipeline);

        g.setMatrix(mvpID, mvp);
        g.setMatrix(jointMatricesIDs[0], jointMatrices[0]);
        g.setMatrix(jointMatricesIDs[1], jointMatrices[1]);

        g.setTextureParameters(texID,
            TextureAddressing.Repeat, TextureAddressing.Repeat,
            TextureFilter.LinearFilter, TextureFilter.LinearFilter,
            MipMapFilter.NoMipFilter
        );
        g.setTexture(texID, Assets.images.uvgrid);

        g.setVertexBuffer(vertexBuffer);
        g.setIndexBuffer(indexBuffer);
        g.drawIndexedVertices();
    }
}
