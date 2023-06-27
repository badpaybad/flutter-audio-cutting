https://dart.dev/guides/libraries/c-interop

# build & run

~/helloclang

CMakeLists.txt
                
                sudo apt install libc6

                cmake .
                make
                or
                cmake --build .
                
                cd ..
                dart hello.dart

                flutter build aar --android-platform android-21

# build run in ARM

/android/app/build.gradle

                android {
                externalNativeBuild {
                cmake {
                path "../../lib/interop/helloclang/CMakeLists.txt"
                }
                }

                sudo apt install gcc-arm-none-eabi                

~/helloclang

     https://developer.android.com/r/tools/jniLibs-vs-imported-targets


                cmake -DCMAKE_TOOLCHAIN_FILE=toolchain-arm.cmake .
                cmake --build .


                Copy the .so library file to the appropriate directory in your Flutter project. The recommended location is the android/app/src/main/jniLibs directory.

                For example, if you have a library called libmylibrary.so, copy it to android/app/src/main/jniLibs/armeabi-v7a/libmylibrary.so for ARM architecture. Adjust the directory structure and library name based on your specific library and target architecture.
                
                Open the android/app/build.gradle file in your Flutter project and add the following lines inside the android section:

                android/build.gradle 
                sourceSets {
                    main.java.srcDirs += 'src/main/kotlin'
                    main.java.srcDirs += 'src/main/jniLibs'
            
                }

                check main.dart and function testFfi()
