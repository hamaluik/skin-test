let project = new Project('Skin Test');

project.addSources('Sources');
project.addShaders('Shaders/**');

project.addLibrary('glm');
project.addLibrary('gltf');

project.addAssets('Assets/**');

project.addParameter('-debug');

// HTML target
project.windowOptions.width = 1280;
project.windowOptions.height = 720;

resolve(project);
