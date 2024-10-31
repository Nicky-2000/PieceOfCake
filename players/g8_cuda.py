import cupy as cp

def polygon_line_intersection(polygon_coords, line_coords):
    """
    Check for intersections between a polygon and a line on the GPU.

    Args:
        polygon_coords (numpy.ndarray): Array of polygon vertices as (x, y) coordinates.
        line_coords (list or numpy.ndarray): Array or list with two points representing the line [(x1, y1), (x2, y2)].

    Returns:
        numpy.ndarray: Array of intersection indicators (1 for intersection, 0 for no intersection) for each polygon edge.
    """
    
    # Transfer data to the GPU
    polygon_coords_gpu = cp.array(polygon_coords, dtype=cp.float32)
    line_coords_gpu = cp.array(line_coords, dtype=cp.float32)

    # Define the CUDA kernel
    polygon_line_intersection_kernel = cp.RawKernel(r'''
    extern "C" __global__
    void polygon_line_intersection(const float* polygon_coords, int n_coords, 
                                   const float* line_coords, int* intersections) {
        int idx = blockDim.x * blockIdx.x + threadIdx.x;
        if (idx >= n_coords - 1) return;

        // Line segment from polygon
        float x1 = polygon_coords[2 * idx];
        float y1 = polygon_coords[2 * idx + 1];
        float x2 = polygon_coords[2 * (idx + 1)];
        float y2 = polygon_coords[2 * (idx + 1) + 1];

        // Line segment for test line
        float lx1 = line_coords[0];
        float ly1 = line_coords[1];
        float lx2 = line_coords[2];
        float ly2 = line_coords[3];

        // Calculate intersection (based on determinant approach)
        float denominator = (x1 - x2) * (ly1 - ly2) - (y1 - y2) * (lx1 - lx2);
        if (fabs(denominator) < 1e-6) {
            intersections[idx] = 0;  // Parallel lines, no intersection
            return;
        }

        float t = ((x1 - lx1) * (ly1 - ly2) - (y1 - ly1) * (lx1 - lx2)) / denominator;
        float u = -((x1 - x2) * (y1 - ly1) - (y1 - y2) * (x1 - lx1)) / denominator;

        // Check if intersection point lies on both segments
        intersections[idx] = (t >= 0 && t <= 1 && u >= 0 && u <= 1) ? 1 : 0;
    }
    ''', 'polygon_line_intersection')

    # Allocate output array for results
    n_coords = polygon_coords.shape[0]
    intersections_gpu = cp.zeros(n_coords, dtype=cp.int32)

    # Determine thread and block configuration
    threads_per_block = 32
    blocks_per_grid = (n_coords + threads_per_block - 1) // threads_per_block

    # Launch the kernel
    polygon_line_intersection_kernel(
        (blocks_per_grid,), (threads_per_block,),
        (polygon_coords_gpu, n_coords, line_coords_gpu, intersections_gpu)
    )

    # Retrieve and return the results
    intersections = intersections_gpu.get()
    return intersections
