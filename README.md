 ## basic notes

- Engine coordinates the application.
 - GPU owns frame rendering and presentation.
 - Device, Pipeline, and Shader wrap SDL3 GPU resources.
 - ImGUILayer owns ImGui integration.
 - Window owns the SDL window.
 - CMake automatically builds portable shader formats.
