import {vec3} from 'gl-matrix';
import {vec4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';
import {gl} from './globals';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  'Load Scene': loadScene, // A function pointer, essentially
  movingFrequency: 0.005,
  bumpiness: 3.0,
  intensity: 1.0,
  reset: reset,
};

let icosphere: Icosphere;
let square: Square;
let cube: Cube;
let prevTesselations: number = 5;
let time: number = 0;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();
}

function reset(){
  controls.movingFrequency = 0.005;
  controls.bumpiness = 3.0;
  controls.intensity = 1.0;
}


function loadTexture(url: string) {
  const texture = gl.createTexture();
  const image = new Image();

  image.onload = e => {
      gl.bindTexture(gl.TEXTURE_2D, texture);
      
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);

      gl.generateMipmap(gl.TEXTURE_2D);
  };

  image.src = url;
  return texture;
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'Load Scene');
  gui.add(controls, 'reset');
  gui.add(controls, 'movingFrequency', 0.005, 0.05).step(0.001);
  gui.add(controls, 'bumpiness', 1.0, 10.0).step(1.0);
  gui.add(controls, 'intensity', 1.0, 10.0).step(1.0);

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  // ---- load texture
  const gradientTexture = loadTexture('../texture/gradient.png');
  gl.activeTexture(gl.TEXTURE0);
  gl.bindTexture(gl.TEXTURE_2D, gradientTexture);

  const gradientTexture2 = loadTexture('../texture/gradient2.png');
  gl.activeTexture(gl.TEXTURE1);
  gl.bindTexture(gl.TEXTURE_2D, gradientTexture2);

  const deformShader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-deform-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-deform-frag.glsl')),
  ])

  const worleyShader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-worley-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-worley-frag.glsl')),
  ])

  deformShader.setTexture(0);
  worleyShader.setTexture(1);


  // ========= audio
  const play = require('audio-play');
  const load = require('audio-loader');
  
  //load('./music/running_up_the_hill.mp3').then(play);


  // This function will be called every frame
  function tick() {
    time = time + 1;
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }
    
    deformShader.setTime(time);  
    worleyShader.setTime(time);
    deformShader.setFrequency(controls.movingFrequency);  
    deformShader.setBumpiness(controls.bumpiness);  
    deformShader.setIntensity(controls.intensity);                                                
    renderer.render(camera, worleyShader, [
      // icosphere,
      square,
      //cube
    ]);
    renderer.render(camera, deformShader, [
      icosphere,
      //square
      //cube
    ]);
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
