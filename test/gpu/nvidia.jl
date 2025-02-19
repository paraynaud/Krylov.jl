using LinearAlgebra, SparseArrays, Test
using LinearOperators, Krylov, CUDA, CUDA.CUSPARSE, CUDA.CUSOLVER

include("../test_utils.jl")

include("../test_utils.jl")

@testset "Nvidia -- CUDA.jl" begin

  @test CUDA.functional()
  CUDA.allowscalar(false)

  @testset "documentation" begin
    A_cpu = rand(20, 20)
    b_cpu = rand(20)
    A_gpu = CuMatrix(A_cpu)
    b_gpu = CuVector(b_cpu)
    x, stats = bilq(A_gpu, b_gpu)

    A_cpu = sprand(200, 100, 0.3)
    b_cpu = rand(200)
    A_gpu = CuSparseMatrixCSC(A_cpu)
    b_gpu = CuVector(b_cpu)
    x, stats = lsmr(A_gpu, b_gpu)

    @testset "ic0" begin
      A_cpu, b_cpu = sparse_laplacian()

      b_gpu = CuVector(b_cpu)
      n = length(b_gpu)
      T = eltype(b_gpu)
      symmetric = hermitian = true

      A_gpu = CuSparseMatrixCSC(A_cpu)
      P = ic02(A_gpu, 'O')
      function ldiv_ic0!(y, P, x)
        copyto!(y, x)
        sv2!('T', 'U', 'N', 1.0, P, y, 'O')
        sv2!('N', 'U', 'N', 1.0, P, y, 'O')
        return y
      end
      opM = LinearOperator(T, n, n, symmetric, hermitian, (y, x) -> ldiv_ic0!(y, P, x))
      x, stats = cg(A_gpu, b_gpu, M=opM)
      @test norm(b_gpu - A_gpu * x) ≤ 1e-6

      A_gpu = CuSparseMatrixCSR(A_cpu)
      P = ic02(A_gpu, 'O')
      function ldiv_ic0!(y, P, x)
        copyto!(y, x)
        sv2!('N', 'L', 'N', 1.0, P, y, 'O')
        sv2!('T', 'L', 'N', 1.0, P, y, 'O')
        return y
      end
      opM = LinearOperator(T, n, n, symmetric, hermitian, (y, x) -> ldiv_ic0!(y, P, x))
      x, stats = cg(A_gpu, b_gpu, M=opM)
      @test norm(b_gpu - A_gpu * x) ≤ 1e-6
    end

    @testset "ilu0" begin
      A_cpu, b_cpu = polar_poisson()

      p = zfd(A_cpu, 'O')
      p .+= 1
      A_cpu = A_cpu[p,:]
      b_cpu = b_cpu[p]

      b_gpu = CuVector(b_cpu)
      n = length(b_gpu)
      T = eltype(b_gpu)
      symmetric = hermitian = false

      A_gpu = CuSparseMatrixCSC(A_cpu)
      P = ilu02(A_gpu, 'O')
      function ldiv_ilu0!(y, P, x)
        copyto!(y, x)
        sv2!('N', 'L', 'N', 1.0, P, y, 'O')
        sv2!('N', 'U', 'U', 1.0, P, y, 'O')
        return y
      end
      opM = LinearOperator(T, n, n, symmetric, hermitian, (y, x) -> ldiv_ilu0!(y, P, x))
      x, stats = bicgstab(A_gpu, b_gpu, M=opM)
      @test norm(b_gpu - A_gpu * x) ≤ 1e-6

      A_gpu = CuSparseMatrixCSR(A_cpu)
      P = ilu02(A_gpu, 'O')
      function ldiv_ilu0!(y, P, x)
        copyto!(y, x)
        sv2!('N', 'L', 'U', 1.0, P, y, 'O')
        sv2!('N', 'U', 'N', 1.0, P, y, 'O')
        return y
      end
      opM = LinearOperator(T, n, n, symmetric, hermitian, (y, x) -> ldiv_ilu0!(y, P, x))
      x, stats = bicgstab(A_gpu, b_gpu, M=opM)
      @test norm(b_gpu - A_gpu * x) ≤ 1e-6
    end
  end

  for FC in (Float32, Float64, ComplexF32, ComplexF64)
    S = CuVector{FC}
    T = real(FC)
    n = 10
    x = rand(FC, n)
    x = S(x)
    y = rand(FC, n)
    y = S(y)
    a = rand(FC)
    b = rand(FC)
    s = rand(FC)
    a2 = rand(T)
    b2 = rand(T)
    c = rand(T)

    @testset "kdot -- $FC" begin
      Krylov.@kdot(n, x, y)
    end

    @testset "kdotr -- $FC" begin
      Krylov.@kdotr(n, x, y)
    end

    @testset "knrm2 -- $FC" begin
      Krylov.@knrm2(n, x)
    end

    @testset "kaxpy! -- $FC" begin
      Krylov.@kaxpy!(n, a, x, y)
      Krylov.@kaxpy!(n, a2, x, y)
    end

    @testset "kaxpby! -- $FC" begin
      Krylov.@kaxpby!(n, a, x, b, y)
      Krylov.@kaxpby!(n, a2, x, b, y)
      Krylov.@kaxpby!(n, a, x, b2, y)
      Krylov.@kaxpby!(n, a2, x, b2, y)
    end

    @testset "kcopy! -- $FC" begin
      Krylov.@kcopy!(n, x, y)
    end

    @testset "kswap -- $FC" begin
      Krylov.@kswap(x, y)
    end

    @testset "kref! -- $FC" begin
      Krylov.@kref!(n, x, y, c, s)
    end

    ε = eps(T)
    atol = √ε
    rtol = √ε

    @testset "GMRES -- $FC" begin
      A, b = nonsymmetric_indefinite(FC=FC)
      A = CuMatrix{FC}(A)
      b = CuVector{FC}(b)
      x, stats = gmres(A, b)
      @test norm(b - A * x) ≤ atol + rtol * norm(b)
    end

    @testset "CG -- $FC" begin
      A, b = symmetric_definite(FC=FC)
      A = CuMatrix{FC}(A)
      b = CuVector{FC}(b)
      x, stats = cg(A, b)
      @test norm(b - A * x) ≤ atol + rtol * norm(b)
    end
  end
end
