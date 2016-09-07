# Cubenado
OpenGL ES 3.0 demo for iOS

<img src="./Images/Cubenado_withShadow.png" height="400px">

The goal for this demo is to animate a tornado of cubes with a high degree of adjustability in cube motion, as well as being able to handle simulating 10K cubes on a mobile device at real-time framerates.



## Implementation
The curvature of the tornado is modeled using a 3rd degree Bezier curve.  Particle motion is simulated using transform feedback resulting in cubes that oribit around the tangents of the tornado Bezier curve.  During each frame, after particle simulation, the particles are rendered as instanced cubes, each with their own unique axis of orientation and position. 


Increasing the cube randomness slider affects various aspects of the tornado motion:
* Each cube is rotated about a unique axis by an angle proportional to cube randomness.
* Debris particles are generated in greater amounts for higher randomness values.
* Rotational movement of tornado end points is increased.
* Rotational speed of cube particles is greater for higher values of cube randomness. 

In addition to tornado motion, shadow mapping was used to render a shadow of the tornado onto a ground plane to give a better sense of 3D perspective and light direction.  



## Performance Measure
Below is a screen shot taken with XCode GPU Report of Cubenado running on an Apple A7 GPU.  Fluid framerate of 60fps was reported for simulating and rendering the maximum of 10k cube particles with shadows.  Notice also the reduced CPU usage per frame due to minimal updates on the CPU with nearly all work being processed on the GPU.  Therefore, for future enhancements there is a lot of room left to take advantage of CPU processing. 
<img src="./Images/Cubenado 10K cubes.png" height="300px">
<img src="./Images/Cubenado Perf Analysis.png" height="300px">

