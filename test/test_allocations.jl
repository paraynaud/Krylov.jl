@testset "allocations" begin

  for FC in (Float64, ComplexF64)
    @testset "Data Type: $FC" begin

      A   = FC.(get_div_grad(16, 16, 16))  # Dimension n x n
      n   = size(A, 1)
      m   = div(n, 2)
      Au  = A[1:m,:]  # Dimension m x n
      Ao  = A[:,1:m]  # Dimension n x m
      b   = Ao * ones(FC, m) # Dimension n
      c   = Au * ones(FC, n) # Dimension m
      mem = 200

      shifts  = [1.0; 2.0; 3.0; 4.0; 5.0]
      nshifts = 5
      nbits = sizeof(FC)  # 8 bits for Float64 and 16 bits for ComplexF64

      @testset "SYMMLQ" begin
        # SYMMLQ needs:
        # 5 n-vectors: x, Mvold, Mv, Mv_next, w̅
        storage_symmlq(n) = 5 * n
        storage_symmlq_bytes(n) = nbits * storage_symmlq(n)

        expected_symmlq_bytes = storage_symmlq_bytes(n)
        symmlq(A, b)  # warmup
        actual_symmlq_bytes = @allocated symmlq(A, b)
        @test expected_symmlq_bytes ≤ actual_symmlq_bytes ≤ 1.02 * expected_symmlq_bytes

        solver = SymmlqSolver(A, b)
        symmlq!(solver, A, b)  # warmup
        inplace_symmlq_bytes = @allocated symmlq!(solver, A, b)
        @test inplace_symmlq_bytes == 0
      end

      @testset "CG" begin
        # CG needs:
        # 4 n-vectors: x, r, p, Ap
        storage_cg(n) = 4 * n
        storage_cg_bytes(n) = nbits * storage_cg(n)

        expected_cg_bytes = storage_cg_bytes(n)
        cg(A, b)  # warmup
        actual_cg_bytes = @allocated cg(A, b)
        @test expected_cg_bytes ≤ actual_cg_bytes ≤ 1.02 * expected_cg_bytes

        solver = CgSolver(A, b)
        cg!(solver, A, b)  # warmup
        inplace_cg_bytes = @allocated cg!(solver, A, b)
        @test inplace_cg_bytes == 0
      end

      @testset "CG-LANCZOS" begin
        # CG-LANCZOS needs:
        # 5 n-vectors: x, Mv, Mv_prev, p, Mv_next
        storage_cg_lanczos(n) = 5 * n
        storage_cg_lanczos_bytes(n) = nbits * storage_cg_lanczos(n)

        expected_cg_lanczos_bytes = storage_cg_lanczos_bytes(n)
        cg_lanczos(A, b)  # warmup
        actual_cg_lanczos_bytes = @allocated cg_lanczos(A, b)
        @test expected_cg_lanczos_bytes ≤ actual_cg_lanczos_bytes ≤ 1.02 * expected_cg_lanczos_bytes

        solver = CgLanczosSolver(A, b)
        cg_lanczos!(solver, A, b)  # warmup
        inplace_cg_lanczos_bytes = @allocated cg_lanczos!(solver, A, b)
        @test inplace_cg_lanczos_bytes == 0
      end

      @testset "CG-LANCZOS-SHIFT" begin
        # CG-LANCZOS-SHIFT needs:
        # - 3 n-vectors: Mv, Mv_prev, Mv_next
        # - 2 (n*nshifts)-matrices: x, p
        # - 5 nshifts-vectors: σ, δhat, ω, γ, rNorms
        # - 3 nshifts-bitVector: indefinite, converged, not_cv
        storage_cg_lanczos_shift(n, nshifts) = (3 * n) + (2 * n * nshifts) + (5 * nshifts) + (3 * nshifts / 64)
        storage_cg_lanczos_shift_bytes(n, nshifts) = nbits * storage_cg_lanczos_shift(n, nshifts)

        expected_cg_lanczos_shift_bytes = storage_cg_lanczos_shift_bytes(n, nshifts)
        cg_lanczos_shift(A, b, shifts)  # warmup
        actual_cg_lanczos_shift_bytes = @allocated cg_lanczos_shift(A, b, shifts)
        @test expected_cg_lanczos_shift_bytes ≤ actual_cg_lanczos_shift_bytes ≤ 1.02 * expected_cg_lanczos_shift_bytes

        solver = CgLanczosShiftSolver(A, b, nshifts)
        cg_lanczos_shift!(solver, A, b, shifts)  # warmup
        inplace_cg_lanczos_shift_bytes = @allocated cg_lanczos_shift!(solver, A, b, shifts)
        @test inplace_cg_lanczos_shift_bytes == 0
      end

      @testset "CR" begin
        # CR needs:
        # 5 n-vectors: x, r, p, q, Ar
        storage_cr(n) = 5 * n
        storage_cr_bytes(n) = nbits * storage_cr(n)

        expected_cr_bytes = storage_cr_bytes(n)
        cr(A, b)  # warmup
        actual_cr_bytes = @allocated cr(A, b)
        @test expected_cr_bytes ≤ actual_cr_bytes ≤ 1.02 * expected_cr_bytes

        solver = CrSolver(A, b)
        cr!(solver, A, b)  # warmup
        inplace_cr_bytes = @allocated cr!(solver, A, b)
        @test inplace_cr_bytes == 0
      end

      @testset "MINRES" begin
        # MINRES needs:
        # 6 n-vectors: x, r1, r2, w1, w2, y
        storage_minres(n) = 6 * n
        storage_minres_bytes(n) = nbits * storage_minres(n)

        expected_minres_bytes = storage_minres_bytes(n)
        minres(A, b)  # warmup
        actual_minres_bytes = @allocated minres(A, b)
        @test expected_minres_bytes ≤ actual_minres_bytes ≤ 1.02 * expected_minres_bytes

        solver = MinresSolver(A, b)
        minres!(solver, A, b)  # warmup
        inplace_minres_bytes = @allocated minres!(solver, A, b)
        @test inplace_minres_bytes == 0
      end

      @testset "MINRES-QLP" begin
        # MINRES-QLP needs:
        # - 6 n-vectors: wₖ₋₁, wₖ, vₖ₋₁, vₖ, x, p
        storage_minres_qlp(n) = 6 * n
        storage_minres_qlp_bytes(n) = nbits * storage_minres_qlp(n)

        expected_minres_qlp_bytes = storage_minres_qlp_bytes(n)
        minres_qlp(A, b)  # warmup
        actual_minres_qlp_bytes = @allocated minres_qlp(A, b)
        @test expected_minres_qlp_bytes ≤ actual_minres_qlp_bytes ≤ 1.02 * expected_minres_qlp_bytes

        solver = MinresQlpSolver(A, b)
        minres_qlp!(solver, A, b)  # warmup
        inplace_minres_qlp_bytes = @allocated minres_qlp!(solver, A, b)
        @test inplace_minres_qlp_bytes == 0
      end

      @testset "DIOM" begin
        # DIOM needs:
        # - 2 n-vectors: x, t
        # - 2 (n*mem)-matrices: P, V
        # - 1 mem-vector: L
        # - 1 (mem+2)-vector: H
        storage_diom(mem, n) = (2 * n) + (2 * n * mem) + (mem) + (mem + 2)
        storage_diom_bytes(mem, n) = nbits * storage_diom(mem, n)

        expected_diom_bytes = storage_diom_bytes(mem, n)
        diom(A, b, memory=mem)  # warmup
        actual_diom_bytes = @allocated diom(A, b, memory=mem)
        @test expected_diom_bytes ≤ actual_diom_bytes ≤ 1.02 * expected_diom_bytes

        solver = DiomSolver(A, b, mem)
        diom!(solver, A, b)  # warmup
        inplace_diom_bytes = @allocated diom!(solver, A, b)
        @test inplace_diom_bytes == 0
      end

      @testset "FOM" begin
        # FOM needs:
        # - 2 n-vectors: x, w
        # - 1 (n*mem)-matrix: V
        # - 2 mem-vectors: l, z
        # - 1 (mem*(mem+1)/2)-vector: U
        storage_fom(mem, n) = (2 * n) + (n * mem) + (2 * mem) + (mem * (mem+1) / 2)
        storage_fom_bytes(mem, n) = nbits * storage_fom(mem, n)

        expected_fom_bytes = storage_fom_bytes(mem, n)
        fom(A, b, memory=mem)  # warmup
        actual_fom_bytes = @allocated fom(A, b, memory=mem)
        @test expected_fom_bytes ≤ actual_fom_bytes ≤ 1.02 * expected_fom_bytes

        solver = FomSolver(A, b, mem)
        fom!(solver, A, b)  # warmup
        inplace_fom_bytes = @allocated fom!(solver, A, b)
        @test inplace_fom_bytes == 0
      end

      @testset "DQGMRES" begin
        # DQGMRES needs:
        # - 2 n-vectors: x, t
        # - 2 (n*mem)-matrices: P, V
        # - 2 mem-vectors: c, s
        # - 1 (mem+2)-vector: H
        storage_dqgmres(mem, n) = (2 * n) + (2 * n * mem) + (2 * mem) + (mem + 2)
        storage_dqgmres_bytes(mem, n) = nbits * storage_dqgmres(mem, n)

        expected_dqgmres_bytes = storage_dqgmres_bytes(mem, n)
        dqgmres(A, b, memory=mem)  # warmup
        actual_dqgmres_bytes = @allocated dqgmres(A, b, memory=mem)
        @test expected_dqgmres_bytes ≤ actual_dqgmres_bytes ≤ 1.02 * expected_dqgmres_bytes

        solver = DqgmresSolver(A, b, mem)
        dqgmres!(solver, A, b)  # warmup
        inplace_dqgmres_bytes = @allocated dqgmres!(solver, A, b)
        @test inplace_dqgmres_bytes == 0
      end

      @testset "GMRES" begin
        # GMRES needs:
        # - 2 n-vectors: x, w
        # - 1 n*(mem)-matrix: V
        # - 3 mem-vectors: c, s, z
        # - 1 (mem*(mem+1)/2)-vector: R
        storage_gmres(mem, n) = (2 * n) + (n * mem) + (3 * mem) + (mem * (mem+1) / 2)
        storage_gmres_bytes(mem, n) = nbits * storage_gmres(mem, n)

        expected_gmres_bytes = storage_gmres_bytes(mem, n)
        gmres(A, b, memory=mem)  # warmup
        actual_gmres_bytes = @allocated gmres(A, b, memory=mem)
        @test expected_gmres_bytes ≤ actual_gmres_bytes ≤ 1.02 * expected_gmres_bytes

        solver = GmresSolver(A, b, mem)
        gmres!(solver, A, b)  # warmup
        inplace_gmres_bytes = @allocated gmres!(solver, A, b)
        @test inplace_gmres_bytes == 0
      end

      @testset "CGS" begin
        # CGS needs:
        # 6 n-vectors: x, r, u, p, q, ts
        storage_cgs(n) = 6 * n
        storage_cgs_bytes(n) = nbits * storage_cgs(n)

        expected_cgs_bytes = storage_cgs_bytes(n)
        cgs(A, b)  # warmup
        actual_cgs_bytes = @allocated cgs(A, b)
        @test expected_cgs_bytes ≤ actual_cgs_bytes ≤ 1.02 * expected_cgs_bytes

        solver = CgsSolver(A, b)
        cgs!(solver, A, b)  # warmup
        inplace_cgs_bytes = @allocated cgs!(solver, A, b)
        @test inplace_cgs_bytes == 0
      end

      @testset "BICGSTAB" begin
        # BICGSTAB needs:
        # 6 n-vectors: x, r, p, v, s, qd
        storage_bicgstab(n) = 6 * n
        storage_bicgstab_bytes(n) = nbits * storage_bicgstab(n)

        expected_bicgstab_bytes = storage_bicgstab_bytes(n)
        bicgstab(A, b)  # warmup
        actual_bicgstab_bytes = @allocated bicgstab(A, b)
        @test expected_bicgstab_bytes ≤ actual_bicgstab_bytes ≤ 1.02 * expected_bicgstab_bytes

        solver = BicgstabSolver(A, b)
        bicgstab!(solver, A, b)  # warmup
        inplace_bicgstab_bytes = @allocated bicgstab!(solver, A, b)
        @test inplace_bicgstab_bytes == 0
      end

      @testset "CGNE" begin
        # CGNE needs:
        # - 3 n-vectors: x, p, Aᴴz
        # - 2 m-vectors: r, q
        storage_cgne(n, m) = 3 * n + 2 * m
        storage_cgne_bytes(n, m) = nbits * storage_cgne(n, m)

        expected_cgne_bytes = storage_cgne_bytes(n, m)
        (x, stats) = cgne(Au, c)  # warmup
        actual_cgne_bytes = @allocated cgne(Au, c)
        @test expected_cgne_bytes ≤ actual_cgne_bytes ≤ 1.02 * expected_cgne_bytes

        solver = CgneSolver(Au, c)
        cgne!(solver, Au, c)  # warmup
        inplace_cgne_bytes = @allocated cgne!(solver, Au, c)
        @test inplace_cgne_bytes == 0
      end

      @testset "CRMR" begin
        # CRMR needs:
        # - 3 n-vectors: x, p, Aᴴr
        # - 2 m-vectors: r, q
        storage_crmr(n, m) = 3 * n + 2 * m
        storage_crmr_bytes(n, m) = nbits * storage_crmr(n, m)

        expected_crmr_bytes = storage_crmr_bytes(n, m)
        (x, stats) = crmr(Au, c)  # warmup
        actual_crmr_bytes = @allocated crmr(Au, c)
        @test expected_crmr_bytes ≤ actual_crmr_bytes ≤ 1.02 * expected_crmr_bytes

        solver = CrmrSolver(Au, c)
        crmr!(solver, Au, c)  # warmup
        inplace_crmr_bytes = @allocated crmr!(solver, Au, c)
        @test inplace_crmr_bytes == 0
      end

      @testset "LNLQ" begin
        # LNLQ needs:
        # - 3 n-vectors: x, v, Aᴴu
        # - 4 m-vectors: y, w̄, u, Av
        storage_lnlq(n, m) = 3 * n + 4 * m
        storage_lnlq_bytes(n, m) = nbits * storage_lnlq(n, m)

        expected_lnlq_bytes = storage_lnlq_bytes(n, m)
        lnlq(Au, c)  # warmup
        actual_lnlq_bytes = @allocated lnlq(Au, c)
        @test expected_lnlq_bytes ≤ actual_lnlq_bytes ≤ 1.02 * expected_lnlq_bytes

        solver = LnlqSolver(Au, c)
        lnlq!(solver, Au, c)  # warmup
        inplace_lnlq_bytes = @allocated lnlq!(solver, Au, c)
        @test inplace_lnlq_bytes == 0
      end

      @testset "CRAIG" begin
        # CRAIG needs:
        # - 3 n-vectors: x, v, Aᴴu
        # - 4 m-vectors: y, w, u, Av
        storage_craig(n, m) = 3 * n + 4 * m
        storage_craig_bytes(n, m) = nbits * storage_craig(n, m)

        expected_craig_bytes = storage_craig_bytes(n, m)
        craig(Au, c)  # warmup
        actual_craig_bytes = @allocated craig(Au, c)
        @test expected_craig_bytes ≤ actual_craig_bytes ≤ 1.02 * expected_craig_bytes

        solver = CraigSolver(Au, c)
        craig!(solver, Au, c)  # warmup
        inplace_craig_bytes = @allocated craig!(solver, Au, c)
        @test inplace_craig_bytes == 0
      end

      @testset "CRAIGMR" begin
        # CRAIGMR needs:
        # - 4 n-vectors: x, v, Aᴴu, d
        # - 5 m-vectors: y, u, w, wbar, Av
        storage_craigmr(n, m) = 4 * n + 5 * m
        storage_craigmr_bytes(n, m) = nbits * storage_craigmr(n, m)

        expected_craigmr_bytes = storage_craigmr_bytes(n, m)
        craigmr(Au, c)  # warmup
        actual_craigmr_bytes = @allocated craigmr(Au, c)
        @test expected_craigmr_bytes ≤ actual_craigmr_bytes ≤ 1.02 * expected_craigmr_bytes

        solver = CraigmrSolver(Au, c)
        craigmr!(solver, Au, c)  # warmup
        inplace_craigmr_bytes = @allocated craigmr!(solver, Au, c)
        @test inplace_craigmr_bytes == 0
      end

      @testset "CGLS" begin
        # CGLS needs:
        # - 3 m-vectors: x, p, s
        # - 2 n-vectors: r, q
        storage_cgls(n, m) = 3 * m + 2 * n
        storage_cgls_bytes(n, m) = nbits * storage_cgls(n, m)

        expected_cgls_bytes = storage_cgls_bytes(n, m)
        (x, stats) = cgls(Ao, b)  # warmup
        actual_cgls_bytes = @allocated cgls(Ao, b)
        @test expected_cgls_bytes ≤ actual_cgls_bytes ≤ 1.02 * expected_cgls_bytes

        solver = CglsSolver(Ao, b)
        cgls!(solver, Ao, b)  # warmup
        inplace_cgls_bytes = @allocated cgls!(solver, Ao, b)
        @test inplace_cgls_bytes == 0
      end

      @testset "LSLQ" begin
        # LSLQ needs:
        # - 4 m-vectors: x_lq, v, Aᴴu, w̄ (= x_cg)
        # - 2 n-vectors: u, Av
        storage_lslq(n, m) = 4 * m + 2 * n
        storage_lslq_bytes(n, m) = nbits * storage_lslq(n, m)

        expected_lslq_bytes = storage_lslq_bytes(n, m)
        (x, stats) = lslq(Ao, b)  # warmup
        actual_lslq_bytes = @allocated lslq(Ao, b)
        @test expected_lslq_bytes ≤ actual_lslq_bytes ≤ 1.02 * expected_lslq_bytes

        solver = LslqSolver(Ao, b)
        lslq!(solver, Ao, b)  # warmup
        inplace_lslq_bytes = @allocated lslq!(solver, Ao, b)
        @test inplace_lslq_bytes == 0
      end

      @testset "CRLS" begin
        # CRLS needs:
        # - 4 m-vectors: x, p, Ar, q
        # - 3 n-vectors: r, Ap, s
        storage_crls(n, m) = 4 * m + 3 * n
        storage_crls_bytes(n, m) = nbits * storage_crls(n, m)

        expected_crls_bytes = storage_crls_bytes(n, m)
        (x, stats) = crls(Ao, b)  # warmup
        actual_crls_bytes = @allocated crls(Ao, b)
        @test expected_crls_bytes ≤ actual_crls_bytes ≤ 1.02 * expected_crls_bytes

        solver = CrlsSolver(Ao, b)
        crls!(solver, Ao, b)  # warmup
        inplace_crls_bytes = @allocated crls!(solver, Ao, b)
        @test inplace_crls_bytes == 0
      end

      @testset "LSQR" begin
        # LSQR needs:
        # - 4 m-vectors: x, v, w, Aᴴu
        # - 2 n-vectors: u, Av
        storage_lsqr(n, m) = 4 * m + 2 * n
        storage_lsqr_bytes(n, m) = nbits * storage_lsqr(n, m)

        expected_lsqr_bytes = storage_lsqr_bytes(n, m)
        (x, stats) = lsqr(Ao, b)  # warmup
        actual_lsqr_bytes = @allocated lsqr(Ao, b)
        @test expected_lsqr_bytes ≤ actual_lsqr_bytes ≤ 1.02 * expected_lsqr_bytes

        solver = LsqrSolver(Ao, b)
        lsqr!(solver, Ao, b)  # warmup
        inplace_lsqr_bytes = @allocated lsqr!(solver, Ao, b)
        @test inplace_lsqr_bytes == 0
      end

      @testset "LSMR" begin
        # LSMR needs:
        # - 5 m-vectors: x, v, h, hbar, Aᴴu
        # - 2 n-vectors: u, Av
        storage_lsmr(n, m) = 5 * m + 2 * n
        storage_lsmr_bytes(n, m) = nbits * storage_lsmr(n, m)

        expected_lsmr_bytes = storage_lsmr_bytes(n, m)
        (x, stats) = lsmr(Ao, b)  # warmup
        actual_lsmr_bytes = @allocated lsmr(Ao, b)
        @test expected_lsmr_bytes ≤ actual_lsmr_bytes ≤ 1.02 * expected_lsmr_bytes

        solver = LsmrSolver(Ao, b)
        lsmr!(solver, Ao, b)  # warmup
        inplace_lsmr_bytes = @allocated lsmr!(solver, Ao, b)
        @test inplace_lsmr_bytes == 0
      end

      @testset "BiLQ" begin
        # BILQ needs:
        # - 8 n-vectors: uₖ₋₁, uₖ, vₖ₋₁, vₖ, x, d̅, p, q
        storage_bilq(n) = 8 * n
        storage_bilq_bytes(n) = nbits * storage_bilq(n)

        expected_bilq_bytes = storage_bilq_bytes(n)
        bilq(A, b)  # warmup
        actual_bilq_bytes = @allocated bilq(A, b)
        @test expected_bilq_bytes ≤ actual_bilq_bytes ≤ 1.02 * expected_bilq_bytes

        solver = BilqSolver(A, b)
        bilq!(solver, A, b)  # warmup
        inplace_bilq_bytes = @allocated bilq!(solver, A, b)
        @test inplace_bilq_bytes == 0
      end

      @testset "QMR" begin
        # QMR needs:
        # - 9 n-vectors: uₖ₋₁, uₖ, vₖ₋₁, vₖ, x, wₖ₋₁, wₖ, p, q
        storage_qmr(n) = 9 * n
        storage_qmr_bytes(n) = nbits * storage_qmr(n)

        expected_qmr_bytes = storage_qmr_bytes(n)
        qmr(A, b)  # warmup
        actual_qmr_bytes = @allocated qmr(A, b)
        @test expected_qmr_bytes ≤ actual_qmr_bytes ≤ 1.02 * expected_qmr_bytes

        solver = QmrSolver(A, b)
        qmr!(solver, A, b)  # warmup
        inplace_qmr_bytes = @allocated qmr!(solver, A, b)
        @test inplace_qmr_bytes == 0
      end

      @testset "BiLQR" begin
        # BILQR needs:
        # - 11 n-vectors: uₖ₋₁, uₖ, vₖ₋₁, vₖ, x, t, d̅, wₖ₋₁, wₖ, p, q
        storage_bilqr(n) = 11 * n
        storage_bilqr_bytes(n) = nbits * storage_bilqr(n)

        expected_bilqr_bytes = storage_bilqr_bytes(n)
        bilqr(A, b, b)  # warmup
        actual_bilqr_bytes = @allocated bilqr(A, b, b)
        @test expected_bilqr_bytes ≤ actual_bilqr_bytes ≤ 1.02 * expected_bilqr_bytes

        solver = BilqrSolver(A, b)
        bilqr!(solver, A, b, b)  # warmup
        inplace_bilqr_bytes = @allocated bilqr!(solver, A, b, b)
        @test inplace_bilqr_bytes == 0
      end

      @testset "USYMLQ" begin
        # USYMLQ needs:
        # - 5 n-vectors: uₖ₋₁, uₖ, x, d̅, p
        # - 3 m-vectors: vₖ₋₁, vₖ, q
        storage_usymlq(n, m) = 5 * n + 3 * m
        storage_usymlq_bytes(n, m) = nbits * storage_usymlq(n, m)

        expected_usymlq_bytes = storage_usymlq_bytes(n, m)
        usymlq(Au, c, b)  # warmup
        actual_usymlq_bytes = @allocated usymlq(Au, c, b)
        @test expected_usymlq_bytes ≤ actual_usymlq_bytes ≤ 1.02 * expected_usymlq_bytes

        solver = UsymlqSolver(Au, c)
        usymlq!(solver, Au, c, b)  # warmup
        inplace_usymlq_bytes = @allocated usymlq!(solver, Au, c, b)
        @test inplace_usymlq_bytes == 0
      end

      @testset "USYMQR" begin
        # USYMQR needs:
        # - 6 m-vectors: vₖ₋₁, vₖ, x, wₖ₋₁, wₖ, p
        # - 3 n-vectors: uₖ₋₁, uₖ, q
        storage_usymqr(n, m) = 6 * m + 3 * n
        storage_usymqr_bytes(n, m) = nbits * storage_usymqr(n, m)

        expected_usymqr_bytes = storage_usymqr_bytes(n, m)
        (x, stats) = usymqr(Ao, b, c) # warmup
        actual_usymqr_bytes = @allocated usymqr(Ao, b, c)
        @test expected_usymqr_bytes ≤ actual_usymqr_bytes ≤ 1.02 * expected_usymqr_bytes

        solver = UsymqrSolver(Ao, b)
        usymqr!(solver, Ao, b, c)  # warmup
        inplace_usymqr_bytes = @allocated usymqr!(solver, Ao, b, c)
        @test inplace_usymqr_bytes == 0
      end

      @testset "TriLQR" begin
        # TRILQR needs:
        # - 6 m-vectors: vₖ₋₁, vₖ, t, wₖ₋₁, wₖ, q
        # - 5 n-vectors: uₖ₋₁, uₖ, x, d̅, p
        storage_trilqr(n, m) = 6 * m + 5 * n
        storage_trilqr_bytes(n, m) = nbits * storage_trilqr(n, m)

        expected_trilqr_bytes = storage_trilqr_bytes(n, n)
        trilqr(A, b, b)  # warmup
        actual_trilqr_bytes = @allocated trilqr(A, b, b)
        @test expected_trilqr_bytes ≤ actual_trilqr_bytes ≤ 1.02 * expected_trilqr_bytes

        solver = TrilqrSolver(A, b)
        trilqr!(solver, A, b, b)  # warmup
        inplace_trilqr_bytes = @allocated trilqr!(solver, A, b, b)
        @test inplace_trilqr_bytes == 0
      end

      @testset "TriCG" begin
        # TriCG needs:
        # - 6 n-vectors: yₖ, uₖ₋₁, uₖ, gy₂ₖ₋₁, gy₂ₖ, p
        # - 6 m-vectors: xₖ, vₖ₋₁, vₖ, gx₂ₖ₋₁, gx₂ₖ, q
        storage_tricg(n, m) = 6 * n + 6 * m
        storage_tricg_bytes(n, m) = nbits * storage_tricg(n, m)

        expected_tricg_bytes = storage_tricg_bytes(n, m)
        tricg(Au, c, b)  # warmup
        actual_tricg_bytes = @allocated tricg(Au, c, b)
        @test expected_tricg_bytes ≤ actual_tricg_bytes ≤ 1.02 * expected_tricg_bytes

        solver = TricgSolver(Au, c)
        tricg!(solver, Au, c, b)  # warmup
        inplace_tricg_bytes = @allocated tricg!(solver, Au, c, b)
        @test inplace_tricg_bytes == 0
      end

      @testset "TriMR" begin
        # TriMR needs:
        # - 8 n-vectors: yₖ, uₖ₋₁, uₖ, gy₂ₖ₋₃, gy₂ₖ₋₂, gy₂ₖ₋₁, gy₂ₖ, p
        # - 8 m-vectors: xₖ, vₖ₋₁, vₖ, gx₂ₖ₋₃, gx₂ₖ₋₂, gx₂ₖ₋₁, gx₂ₖ, q
        storage_trimr(n, m) = 8 * n + 8 * m
        storage_trimr_bytes(n, m) = nbits * storage_trimr(n, m)

        expected_trimr_bytes = storage_trimr_bytes(n, m)
        trimr(Au, c, b)  # warmup
        actual_trimr_bytes = @allocated trimr(Au, c, b)
        @test expected_trimr_bytes ≤ actual_trimr_bytes ≤ 1.02 * expected_trimr_bytes

        solver = TrimrSolver(Au, c)
        trimr!(solver, Au, c, b)  # warmup
        inplace_trimr_bytes = @allocated trimr!(solver, Au, c, b)
        @test inplace_trimr_bytes == 0
      end

      @testset "GPMR" begin
        # GPMR needs:
        # - 2 n-vectors: x, q
        # - 2 m-vectors: y, p
        # - 1 (n*mem)-matrix: V
        # - 1 (m*mem)-matrix: U
        # - 1 (2*mem)-vector: zt
        # - 2 (4*mem)-vectors: gc, gs
        # - 1 (mem*(2mem+1))-vector: R
        storage_gpmr(mem, n, m) = (mem + 2) * (n + m) + mem * (2 * mem + 11)
        storage_gpmr_bytes(mem, n, m) = nbits * storage_gpmr(mem, n, m)

        expected_gpmr_bytes = storage_gpmr_bytes(mem, n, m)
        gpmr(Ao, Au, b, c, memory=mem, itmax=mem)  # warmup
        actual_gpmr_bytes = @allocated gpmr(Ao, Au, b, c, memory=mem, itmax=mem)
        @test expected_gpmr_bytes ≤ actual_gpmr_bytes ≤ 1.02 * expected_gpmr_bytes

        solver = GpmrSolver(Ao, b, mem)
        gpmr!(solver, Ao, Au, b, c)  # warmup
        inplace_gpmr_bytes = @allocated gpmr!(solver, Ao, Au, b, c)
        @test inplace_gpmr_bytes == 0
      end
    end
  end
end
