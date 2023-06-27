<?php
// Create an FFI instance and load the shared object file
$pathSo = __DIR__ . "/libhello.so";
echo $pathSo."\n" ;
$ffi = FFI::cdef(
    // Function signature
    "int sum(int a, int b);",
    // Path to the shared object file
    $pathSo
);

// Call the function from the shared object
$x = $ffi->sum(1,2);

echo "\n 1+2 = ". $x."\n" ;
?>
