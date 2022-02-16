include("../../src/spinmc.jl")

using ScikitLearn

@sk_import neighbors: NearestNeighbors

phistr = "phi"
dotstr = "dot"

Temps = [0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4]
τvals = [20, 30, 40, 50, 60, 70, 80, 90]

N = 20
spins = rand(Float64, (N, N))
eqsteps = 2000
n_uncorr = 500
phi = true
println("Calculating for N=$(N) ...")

mean_r1 = zeros(Float64, length(Temps))
mean_R = zeros(Float64, length(Temps))

for stepT in 1:length(Temps)
    T = Temps[stepT]
    println("   | Temperature = $(T) ...")

    println("   |   > Equlibrating system ...")
    xy_equilibrate_system!(spins, T, eqsteps)

    # println("   |   > Calculating correlation time ...")
    # τ = xy_getcorrtime!(spins, T)
    # println("   |   > Done.")
    τ = τvals[stepT]

    println("   |   > Making uncorrelated measurements (τ=$(τ)) ...")
    uncorrelated_spins = xy_getuncorrconfigs!(spins, T, τ, n_uncorr)
    println("   |   > Done.")

    println("   |   > Calculating Distances ...")
    # fit the kNN algorithm to uncorrelated spin configs
    model = NearestNeighbors(n_neighbors = 2, algorithm = "ball_tree")
    configs_vec = configs_vec = xy_prepare_vector(uncorrelated_spins)
    nnbrs = fit!(model, configs_vec)  # Ignore warning 

    # calculate distances
    dists, idxs = NearestNeighbors.kneighbors(nnbrs, configs_vec)
    println("   |   > Done.")

    mult(a,b) = a*b
    metric = phi ? mult : xy_spindot
    println("   |   > Calculating Structure Factors ...")
    struc_factors = [structure_factor(uncorrelated_spins[:, :, i], N; metric=metric) for i = 1:size(uncorrelated_spins)[3]]
    println("   |   > Done.")

    mean_r1[stepT] = mean(dists[:, 2])
    mean_R[stepT] = mean(struc_factors)
end

##
println("Plotting ⟨R⟩ v/s ⟨r₁⟩ ...")
f = Figure(resolution = (800, 600))
ax = Axis(f[1, 1], xlabel = "⟨r₁⟩", ylabel = "⟨R$(phi ? phistr : dotstr)⟩", title = "Lattice size = $(N)")
# cols = cgrad(:matter, length(Temps), categorical=true, rev=true)
scatter_points = Point2f.(mean_r1, mean_R)
plt = scatter!(ax, scatter_points, color=1:length(Temps))
Colorbar(
    f[1,2],
    # colormap = cgrad(:matter, rev=true),
    limits = (Temps[1], Temps[end]),
    ticks = Temps[1:end], tickalign=1,
    label="Temperature"
)

ylims!(0.0, 0.5)
# display(f)
save("results/xy/$(N)x$(N)/mean_r1_mean_R$(phi ? phistr : dotstr)_w_T_$(N)_xywolff.png", f)
println("Done.")
##