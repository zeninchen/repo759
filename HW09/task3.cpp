#include <mpi.h>
#include <vector>
#include <iostream>
#include <cstdlib>

int main(int argc, char* argv[]) {
    MPI_Init(&argc, &argv);

    int rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    int n = std::atoi(argv[1]);

    std::vector<float> send_buf(n, 1.0f);
    std::vector<float> recv_buf(n, 0.0f);

    int partner = (rank == 0) ? 1 : 0;
    int tag = 0;

    double t0 = 0.0, t1 = 0.0;

    if (rank == 0) {
        double start = MPI_Wtime();
        MPI_Send(send_buf.data(), n, MPI_FLOAT, partner, tag, MPI_COMM_WORLD);
        MPI_Recv(recv_buf.data(), n, MPI_FLOAT, partner, tag, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        double end = MPI_Wtime();
        t0 = (end - start) * 1000.0;
    } else if (rank == 1) {
        double start = MPI_Wtime();
        MPI_Recv(recv_buf.data(), n, MPI_FLOAT, partner, tag, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        MPI_Send(send_buf.data(), n, MPI_FLOAT, partner, tag, MPI_COMM_WORLD);
        double end = MPI_Wtime();
        t1 = (end - start) * 1000.0;
        MPI_Send(&t1, 1, MPI_DOUBLE, 0, 1, MPI_COMM_WORLD);
    }

    if (rank == 0) {
        MPI_Recv(&t1, 1, MPI_DOUBLE, 1, 1, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        std::cout << t0 + t1 << "\n";
    }

    MPI_Finalize();
    return 0;
}