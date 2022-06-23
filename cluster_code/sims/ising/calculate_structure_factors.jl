include("../../src/spinmc.jl")

basepath = "D:/Projects/Dr. Heyl Group/data/"
println("Using data from: $basepath")

Temps = [1.8, 1.9, 2.0, 2.1, 2.12, 2.14, 2.16, 2.18, 2.2, 2.22, 2.24, 2.26, 2.28, 2.3, 2.32, 2.34, 2.36, 2.38, 2.4, 2.5, 2.6, 2.7]

lattice_sizes = [16, 32, 48, 64]
for N in lattice_sizes
    println("Calculating For N=$(N) ...")
    Threads.@threads for stepT in eachindex(Temps)
        T = Temps[stepT]
        println("| Process strarted on thread #$(Threads.threadid()): T = $(T)")
        datafile = joinpath([basepath, "ising", "uncorr_configs", "Size$N", "ising_uncorr_configs_temp$(T)_size$(N).txt"])
        if !isfile(datafile)
            println("| No Data Found (T=$(T)).")
            println("| Process ended on thread #$(Threads.threadid()): T = $(T)")
            continue
        end

        el = @elapsed begin
            uncorrelated_spins = reshape(readdlm(datafile, ',', Float64), N, N, :)
            struc_facs = [structure_factor(uncorrelated_spins[:, :, i], N; scaled=false) for i = 1:size(uncorrelated_spins)[3]]
    
            szpath = joinpath([basepath, "ising", "struc_facs", "Size$N"])
            ispath(szpath) ? 1 : mkpath(szpath)
            open(joinpath([szpath, "struc_facs_temp$(T)_size$(N).txt"]), "w") do io
                writedlm(io, struc_facs, ',')
            end; 
        end
        println("| Process completed on thread #$(Threads.threadid()) (T = $(T)) in $(el) seconds.")
    end
end