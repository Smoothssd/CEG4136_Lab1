//#include <GL/glut.h>
//#include <vector>
//#include <iostream>
//#include <random>    // Pour std::shuffle et std::mt19937 // For std::shuffle and std::mt19937
//#include <algorithm> // Pour std::shuffle // For std::shuffle
//#include <stdlib.h>
//#include <stdio.h>
//#include <time.h>
//#include <chrono>
//
//#include "cuda.h"
//#include "cuda_runtime.h"
//#include "curand_kernel.h"
//#include "device_launch_parameters.h"
//
//#define N 1000  // Taille de la grille // Grid size
//#define BURN_DURATION 5000  // Dur�e de combustion d'un arbre en millisecondes (5 secondes) // Tree burning duration in milliseconds (5 seconds)
//#define FIRE_START_COUNT 100  // Nombre initial d'incendies // Initial number of fire locations
//
//// Utilisation de vecteurs pour g�rer la m�moire // Using vectors to manage memory
//// use one-dimension vector
//bool useCUDA = false;
//
//std::vector<int> forest(N* N, 0);
//std::vector<int> burnTime(N* N, 0);
//
//int simulationDuration = 60000;  // Dur�e de la simulation (60 secondes) // Simulation duration (60 seconds)
//int startTime = 0;  // Temps de d�part en millisecondes // Start time in milliseconds
//int elapsedTime = 0;  // Temps �coul� // Elapsed time
//float spreadProbability = 0.3f;  // Probabilit� que le feu se propage � un arbre voisin // Probability that fire spreads to a neighboring tree
//
//bool isPaused = false;  // Indicateur de pause // Pause indicator
//int pauseStartTime = 0;  // Temps de d�but de la pause // Start time of pause
//
//float zoomLevel = 1.0f;  // Niveau de zoom // Zoom level
//float offsetX = 0.0f, offsetY = 0.0f;  // D�calage horizontal et vertical pour le d�placement // Horizontal and vertical offset for movement
//float moveSpeed = 0.05f;  // Vitesse de d�placement de la vue // View movement speed
//
//bool dragging = false;  // Indicateur de glisser-d�poser avec la souris // Mouse drag indicator
//int lastMouseX, lastMouseY;  // Derni�re position de la souris lors du clic // Last mouse position when clicked
//
//// Device pointers
//int* d_forest = nullptr;
//int* d_burnTime = nullptr;
//int* d_new_forest = nullptr;
//int* d_new_burnTime = nullptr;
//
////// Define global curandState array
////curandState* d_states = nullptr;
////
////// Kernel to initialize curandState array
////__global__ void initCurandStates(curandState* states, unsigned long seed, int d_N) {
////    int idx = blockIdx.x * blockDim.x + threadIdx.x;
////    int jdx = blockIdx.y * blockDim.y + threadIdx.y;
////    if (idx < d_N && jdx < d_N) {
////        int index = idx * d_N + jdx;
////        curand_init(seed, index, 0, &states[index]);
////    }
////}
//
//
//// Function to check CUDA errors
//#define cudaCheckError() {                                           \
//    cudaError_t e=cudaGetLastError();                                \
//    if(e!=cudaSuccess) {                                             \
//        printf("CUDA Error %s:%d: %s\n", __FILE__, __LINE__,         \
//                cudaGetErrorString(e));                              \
//        exit(EXIT_FAILURE);                                          \
//    }                                                                \
//}
//
//// CUDA Kernel to update the forest
//__global__ void updateForestKernel(int* d_forest, int* d_burnTime, int* d_new_forest, int* d_new_burnTime, int d_N, float spreadProbability, curandState* states) {
//    int idx = blockIdx.x * blockDim.x + threadIdx.x;
//    int jdx = blockIdx.y * blockDim.y + threadIdx.y;
//
//    if (idx < d_N && jdx < d_N) {
//        int index = idx * d_N + jdx;
//
//        // optimize random state
//        curandState localState = states[index];
//        // Initialize new forest and burnTime with current values
//        d_new_forest[index] = d_forest[index];
//        d_new_burnTime[index] = d_burnTime[index];
//
//        if (d_forest[index] == 2) {         // If the tree is on fire
//            d_new_burnTime[index] -= 200;   // Decrease burning time by 200 ms
//
//            if (d_new_burnTime[index] <= 0) {
//                d_new_forest[index] = 3;    // Mark as burned
//                d_new_burnTime[index] = 0;
//            }
//            else {
//
//                // Spread fire to neighbors with probability
//                // up
//                if (idx > 0) {
//                    int neighbor = (idx - 1) * d_N + jdx;
//                    if (d_forest[neighbor] == 1) {  // If neighbor has a tree
//                        float randVal = curand_uniform(&localState);
//                        if (randVal < spreadProbability) {
//                            d_new_forest[neighbor] = 2;  // Ignite the neighbor tree
//                            d_new_burnTime[neighbor] = BURN_DURATION;  // Set burn duration
//                        }
//                    }
//                }
//                // down
//                if (idx < d_N - 1) {
//                    int neighbor = (idx + 1) * d_N + jdx;
//                    if (d_forest[neighbor] == 1) {
//                        float randVal = curand_uniform(&localState);
//                        if (randVal < spreadProbability) {
//                            d_new_forest[neighbor] = 2;
//                            d_new_burnTime[neighbor] = BURN_DURATION;
//                        }
//                    }
//                }
//                // left
//                if (jdx > 0) {
//                    int neighbor = idx * d_N + (jdx - 1);
//                    if (d_forest[neighbor] == 1) {
//                        float randVal = curand_uniform(&localState);
//                        if (randVal < spreadProbability) {
//                            d_new_forest[neighbor] = 2;
//                            d_new_burnTime[neighbor] = BURN_DURATION;
//                        }
//                    }
//                }
//                // right
//                if (jdx < d_N - 1) {
//                    int neighbor = idx * d_N + (jdx + 1);
//                    if (d_forest[neighbor] == 1) {
//                        float randVal = curand_uniform(&localState);
//                        if (randVal < spreadProbability) {
//                            d_new_forest[neighbor] = 2;
//                            d_new_burnTime[neighbor] = BURN_DURATION;
//                        }
//                    }
//                }
//            }
//        }
//    }
//}
//
//// Fonction pour initialiser la for�t // Function to initialize the forest
//void initializeForest() {
//
//    // Initialisation de la for�t avec 50% d'arbres // Initializing the forest with 50% trees
//    for (int i = 0; i < N; i++) {
//        for (int j = 0; j < N; j++) {
//            forest[i * N + j] = rand() % 2;  // 50% d'arbres (1), 50% vide (0) // 50% trees (1), 50% empty space (0)
//            burnTime[i * N + j] = 0;  // Aucun arbre ne br�le au d�part // No tree is burning at the start
//        }
//    }
//
//    // Liste de positions disponibles pour allumer les feux // List of available positions to start fires
//    std::vector<std::pair<int, int>> availablePositions;
//    for (int i = 0; i < N; i++) {
//        for (int j = 0; j < N; j++) {
//            if (forest[i * N + j] == 1) {  // Ajouter les positions avec des arbres dans la liste // Add positions with trees to the list
//                availablePositions.push_back({ i, j });
//            }
//        }
//    }
//
//    // M�langer les positions disponibles pour une distribution plus uniforme // Shuffle the available positions for a more uniform distribution
//    std::random_device rd;  // G�n�rateur de nombres al�atoires bas� sur l'impl�mentation du syst�me // Random number generator based on system implementation
//    std::mt19937 g(rd());   // G�n�rateur de nombres pseudo-al�atoires bas� sur Mersenne Twister // Mersenne Twister-based pseudo-random number generator
//    std::shuffle(availablePositions.begin(), availablePositions.end(), g);
//
//    // Allumer des feux de mani�re uniforme sur la grille // Ignite fires uniformly across the grid
//    for (int fire = 0; fire < FIRE_START_COUNT && !availablePositions.empty(); fire++) {
//        int fireX = availablePositions[fire].first;
//        int fireY = availablePositions[fire].second;
//
//        forest[fireX * N + fireY] = 2;  // Allumer l'arbre en feu // Ignite the tree
//        burnTime[fireX * N + fireY] = BURN_DURATION;  // D�finir le temps de combustion // Set the burn duration
//    }
//
//    startTime = glutGet(GLUT_ELAPSED_TIME);  // R�initialiser le temps de d�part // Reset start time
//    elapsedTime = 0;  // R�initialiser le temps �coul� // Reset elapsed time
//    isPaused = false;  // Fin de la pause // End of pause
//
//
//    // Allocate device memory if not already allocated
//    if (d_forest == nullptr) {
//        cudaMalloc((void**)&d_forest, N * N * sizeof(int));
//        cudaCheckError();
//    }
//    if (d_burnTime == nullptr) {
//        cudaMalloc((void**)&d_burnTime, N * N * sizeof(int));
//        cudaCheckError();
//    }
//    if (d_new_forest == nullptr) {
//        cudaMalloc((void**)&d_new_forest, N * N * sizeof(int));
//        cudaCheckError();
//    }
//    if (d_new_burnTime == nullptr) {
//        cudaMalloc((void**)&d_new_burnTime, N * N * sizeof(int));
//        cudaCheckError();
//    }
//    if (d_states == nullptr) {
//        cudaMalloc((void**)&d_states, N * N * sizeof(curandState));
//    }
//    // Copy initial forest and burnTime to device
//    cudaMemcpy(d_forest, forest.data(), N * N * sizeof(int), cudaMemcpyHostToDevice);
//    cudaCheckError();
//    cudaMemcpy(d_burnTime, burnTime.data(), N * N * sizeof(int), cudaMemcpyHostToDevice);
//    cudaCheckError();
//
//}
//
//// Fonction d'initialisation OpenGL // OpenGL initialization function
//void initGL() {
//    glClearColor(1.0, 1.0, 1.0, 1.0);  // Couleur de fond blanche // White background color
//    glEnable(GL_DEPTH_TEST);  // Activer le test de profondeur // Enable depth test
//}
//
//// Fonction pour dessiner la grille // Function to draw the grid
//void drawForest() {
//    float cellSize = 2.0f / N;  // Taille de chaque cellule ajust�e par la taille N // Adjusted cell size based on grid size N
//
//    for (int i = 0; i < N; i++) {
//        for (int j = 0; j < N; j++) {
//            // Choisir la couleur en fonction de l'�tat de la cellule // Set color based on the state of the cell
//            if (forest[i * N + j] == 0 && burnTime[i * N + j] == 0) {
//                glColor3f(0.8f, 0.8f, 0.8f);  // Espace vide (gris) // Empty space (gray)
//            }
//            else if (forest[i * N + j] == 1) {
//                glColor3f(0.0f, 1.0f, 0.0f);  // Arbre (vert) // Tree (green)
//            }
//            else if (forest[i * N + j] == 2) {
//                glColor3f(1.0f, 0.0f, 0.0f);  // Arbre en feu (rouge) // Tree on fire (red)
//            }
//            else if (forest[i * N + j] == 3) {
//                glColor3f(0.0f, 0.0f, 0.0f);  // Arbre br�l� (noir) // Burned tree (black)
//            }
//
//            // Dessiner la cellule // Draw the cell
//            float x = -1.0f + j * cellSize;
//            float y = -1.0f + i * cellSize;
//            glBegin(GL_QUADS);
//            glVertex2f(x, y);
//            glVertex2f(x + cellSize, y);
//            glVertex2f(x + cellSize, y + cellSize);
//            glVertex2f(x, y + cellSize);
//            glEnd();
//        }
//    }
//}
//
//// use cuda to update the forest and fire propagation
//void updateForestCUDA() {
//
//    // create cuda event
//    cudaEvent_t start, middle, stop;
//    cudaEventCreate(&start);
//    cudaEventCreate(&middle);
//    cudaEventCreate(&stop);
//
//    // record cuda event
//    cudaEventRecord(start, 0);
//
//
//    // Define CUDA block and grid sizes
//    dim3 threadsPerBlock(16, 16);
//    dim3 numBlocks((N + threadsPerBlock.x - 1) / threadsPerBlock.x,
//        (N + threadsPerBlock.y - 1) / threadsPerBlock.y);
//
//    unsigned long seed = time(NULL);  // Use current time as seed
//
//    // init random
//    if (d_states == nullptr) {
//        cudaMalloc(&d_states, N * N * sizeof(curandState));
//        cudaCheckError();
//    }
//    initCurandStates << <numBlocks, threadsPerBlock >> > (d_states, seed, N);
//    cudaCheckError();
//
//    // Launch the CUDA kernel to update the forest
//    updateForestKernel << <numBlocks, threadsPerBlock >> > (d_forest, d_burnTime, d_new_forest, d_new_burnTime, N, spreadProbability, d_states);
//    cudaCheckError();
//    cudaDeviceSynchronize();
//    cudaCheckError();
//
//    cudaEventRecord(middle, 0);
//    cudaEventSynchronize(middle);
//    float middleTime;
//    cudaEventElapsedTime(&middleTime, start, middle);
//    printf("CUDA middleTime took %.3f ms\n", middleTime);
//
//    // Copy new_forest and new_burnTime back to d_forest and d_burnTime
//    cudaMemcpy(d_forest, d_new_forest, N * N * sizeof(int), cudaMemcpyDeviceToDevice);
//    cudaCheckError();
//    cudaMemcpy(d_burnTime, d_new_burnTime, N * N * sizeof(int), cudaMemcpyDeviceToDevice);
//    cudaCheckError();
//
//    // Copy the updated forest and burnTime back to host for rendering
//    cudaMemcpy(forest.data(), d_forest, N * N * sizeof(int), cudaMemcpyDeviceToHost);
//    cudaCheckError();
//    cudaMemcpy(burnTime.data(), d_burnTime, N * N * sizeof(int), cudaMemcpyDeviceToHost);
//    cudaCheckError();
//
//    // Check if all fires are out
//    bool allBurnedOut = true;
//    for (int i = 0; i < N; i++) {
//        for (int j = 0; j < N; j++)
//            if (forest[i * N + j] == 2) {
//                allBurnedOut = false;
//                break;
//            }
//    }
//
//    if (allBurnedOut) {  // Si tous les feux sont �teints, mettre la simulation en pause // If all fires are out, pause the simulation
//        isPaused = true;
//        pauseStartTime = glutGet(GLUT_ELAPSED_TIME);
//    }
//
//    // end cuda event
//    cudaEventRecord(stop, 0);
//    cudaEventSynchronize(stop);
//
//    // calculate time
//    float elapsedTime;
//    cudaEventElapsedTime(&elapsedTime, start, stop);
//    printf("CUDA updateForest took %.3f ms\n", elapsedTime);
//
//    cudaEventDestroy(start);
//    cudaEventDestroy(stop);
//}
//
//// Fonction pour mettre � jour la for�t et la propagation du feu // Function to update the forest and fire propagation
//void updateForestSequential() {
//    auto start = std::chrono::high_resolution_clock::now();
//
//    std::vector<int> newForest = forest;  // Copie la for�t actuelle // Copy the current forest
//
//    bool allBurnedOut = true;  // Indicateur pour v�rifier si tous les feux sont �teints // Flag to check if all fires are out
//
//    for (int i = 0; i < N; i++) {
//        for (int j = 0; j < N; j++) {
//            if (forest[i * N + j] == 2) {  // Si l'arbre est en feu // If the tree is on fire
//                burnTime[i * N + j] -= 200;  // R�duire le temps de combustion // Reduce the burning time
//
//                // V�rifier si le feu est �teint // Check if the fire is out
//                if (burnTime[i * N + j] <= 0) {
//                    newForest[i * N + j] = 3;  // Marquer l'arbre comme br�l� // Mark the tree as burned
//                }
//                else {
//                    // Propagation du feu aux voisins // Propagation of fire to neighbors
//                    if (i > 0 && forest[(i - 1) * N + j] == 1 && (rand() / (float)RAND_MAX) < spreadProbability) {
//                        newForest[(i - 1) * N + j] = 2;
//                        burnTime[(i - 1) * N + j] = BURN_DURATION;
//                    }
//                    if (i < N - 1 && forest[(i + 1) * N + j] == 1 && (rand() / (float)RAND_MAX) < spreadProbability) {
//                        newForest[(i + 1) * N + j] = 2;
//                        burnTime[(i + 1) * N + j] = BURN_DURATION;
//                    }
//                    if (j > 0 && forest[i * N + j - 1] == 1 && (rand() / (float)RAND_MAX) < spreadProbability) {
//                        newForest[i * N + j - 1] = 2;
//                        burnTime[i * N + j - 1] = BURN_DURATION;
//                    }
//                    if (j < N - 1 && forest[i * N + j + 1] == 1 && (rand() / (float)RAND_MAX) < spreadProbability) {
//                        newForest[i * N + j + 1] = 2;
//                        burnTime[i * N + j + 1] = BURN_DURATION;
//                    }
//                }
//            }
//
//            // Si un arbre br�le encore, continuer la simulation // If a tree is still burning, continue the simulation
//            if (forest[i * N + j] == 2) {
//                allBurnedOut = false;
//            }
//        }
//    }
//
//    forest = newForest;  // Mettre � jour la for�t avec la nouvelle copie // Update the forest with the new copy
//
//    if (allBurnedOut) {  // Si tous les feux sont �teints, mettre la simulation en pause // If all fires are out, pause the simulation
//        isPaused = true;
//        pauseStartTime = glutGet(GLUT_ELAPSED_TIME);
//    }
//
//    auto end = std::chrono::high_resolution_clock::now();
//    std::chrono::duration<double, std::milli> elapsed = end - start;
//    printf("Sequential updateForest took %.3f ms\n", elapsed.count());
//}
//
//void updateForest() {
//    if (isPaused) {
//        if (glutGet(GLUT_ELAPSED_TIME) - pauseStartTime >= 3000) {
//            initializeForest();
//        }
//        return;
//    }
//
//    if (useCUDA) {
//        updateForestCUDA();
//    }
//    else {
//        updateForestSequential();
//    }
//}
//
//// Function to free CUDA memory
//void cleanupCUDA() {
//    if (d_forest != nullptr) {
//        cudaFree(d_forest);
//        d_forest = nullptr;
//    }
//    if (d_burnTime != nullptr) {
//        cudaFree(d_burnTime);
//        d_burnTime = nullptr;
//    }
//    if (d_new_forest != nullptr) {
//        cudaFree(d_new_forest);
//        d_new_forest = nullptr;
//    }
//    if (d_new_burnTime != nullptr) {
//        cudaFree(d_new_burnTime);
//        d_new_burnTime = nullptr;
//    }
//}
//
//// Fonction d'affichage // Display function
//void display() {
//    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);  // Effacer le tampon de couleur et de profondeur // Clear color and depth buffer
//    glLoadIdentity();  // R�initialiser la matrice mod�le-vue // Reset the model-view matrix
//    glTranslatef(offsetX, offsetY, 0.0f);  // Appliquer le d�calage // Apply translation offset
//    glScalef(zoomLevel, zoomLevel, 1.0f);  // Appliquer le zoom // Apply zoom
//    drawForest();  // Dessiner la for�t // Draw the forest
//    glutSwapBuffers();  // �changer les tampons pour afficher l'image // Swap buffers to display the image
//}
//
//// Fonction pour animer la simulation // Function to animate the simulation
//void update(int value) {
//    updateForest();  // Mettre � jour la for�t � chaque cycle // Update the forest at each cycle
//    glutPostRedisplay();  // Demander un nouveau rendu // Request a new rendering
//    glutTimerFunc(200, update, 0);  // Programmer la prochaine mise � jour dans 200 ms // Schedule the next update in 200 ms
//}
//
//// Gestion du clavier pour zoomer/d�zoomer et r�initialiser // Keyboard handling for zooming and resetting
//void keyboard(unsigned char key, int x, int y) {
//    switch (key) {
//    case '+':
//        zoomLevel *= 1.1f;  // Augmenter le niveau de zoom // Increase zoom level
//        break;
//    case '-':
//        zoomLevel /= 1.1f;  // Diminuer le niveau de zoom // Decrease zoom level
//        if (zoomLevel < 0.1f) zoomLevel = 0.1f;
//        break;
//    case 'r':  // Touche pour r�initialiser // Reset key
//        zoomLevel = 1.0f;  // R�initialiser le zoom et le d�calage // Reset zoom and offset
//        offsetX = 0.0f;
//        offsetY = 0.0f;
//        break;
//    case 27:  // Touche �chap pour quitter // Escape key to quit
//        exit(0);
//    }
//    glutPostRedisplay();  // Redessiner la sc�ne // Redraw the scene
//}
//
//// Gestion des touches fl�ch�es pour d�placer la vue // Arrow keys handling for moving the view
//void specialKeys(int key, int x, int y) {
//    switch (key) {
//    case GLUT_KEY_UP:
//        offsetY += moveSpeed / zoomLevel;  // D�placer la vue vers le haut // Move the view up
//        break;
//    case GLUT_KEY_DOWN:
//        offsetY -= moveSpeed / zoomLevel;  // D�placer la vue vers le bas // Move the view down
//        break;
//    case GLUT_KEY_LEFT:
//        offsetX += moveSpeed / zoomLevel;  // D�placer la vue vers la gauche // Move the view left
//        break;
//    case GLUT_KEY_RIGHT:
//        offsetX -= moveSpeed / zoomLevel;  // D�placer la vue vers la droite // Move the view right
//        break;
//    }
//    glutPostRedisplay();  // Redessiner la sc�ne // Redraw the scene
//}
//
//// Gestion de la souris pour d�placer la vue // Mouse handling for moving the view
//void mouseMotion(int x, int y) {
//    if (dragging) {
//        offsetX += (x - lastMouseX) * moveSpeed / zoomLevel;  // Mettre � jour le d�calage horizontal // Update horizontal offset
//        offsetY -= (y - lastMouseY) * moveSpeed / zoomLevel;  // Mettre � jour le d�calage vertical // Update vertical offset
//        lastMouseX = x;
//        lastMouseY = y;
//        glutPostRedisplay();  // Redessiner la sc�ne // Redraw the scene
//    }
//}
//
//// Fonction pour g�rer le clic de souris // Function to handle mouse clicks
//void mouse(int button, int state, int x, int y) {
//    if (button == GLUT_LEFT_BUTTON) {  // Si le bouton gauche de la souris est enfonc� // If the left mouse button is pressed
//        if (state == GLUT_DOWN) {
//            dragging = true;
//            lastMouseX = x;
//            lastMouseY = y;
//        }
//        else {
//            dragging = false;
//        }
//    }
//}
//
//// Fonction principale // Main function
//int main(int argc, char** argv) {
//    srand(static_cast<unsigned>(time(NULL)));  // Initialiser le g�n�rateur de nombres al�atoires // Initialize random number generator
//    glutInit(&argc, argv);
//    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB | GLUT_DEPTH);
//    glutInitWindowSize(800, 800);
//    glutCreateWindow("Simulation de feux de for�t/Forest Fire Simulation");  // Cr�er la fen�tre OpenGL // Create the OpenGL window
//
//    initGL();
//    initializeForest();
//
//    glutDisplayFunc(display);
//    glutKeyboardFunc(keyboard);
//    glutSpecialFunc(specialKeys);
//    glutMouseFunc(mouse);
//    glutMotionFunc(mouseMotion);
//    glutTimerFunc(200, update, 0);
//
//    glutMainLoop();
//    cleanupCUDA();
//    return 0;
//}
