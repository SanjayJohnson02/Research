using DelimitedFiles
using DataFrames
using SolverBenchmark

results_dir = joinpath(@__DIR__, "results")
tex_dir = joinpath(@__DIR__, "tex")

# Create the folder "tex" if needed
isdir(tex_dir) || mkdir(tex_dir)

# Generate graphics based on the files generated by kkt.jl
name_tax = ("tax_1d", "tax_2d", "tax_3d", "tax_4d", "tax_5d")

name_cops = ("bearing", "chain", "catmix", "channel", "elec", "gasoil", "marine", "methanol", "minsurf",
             "pinene", "polygon", "robot", "steering", "torsion")

name_pglib = ("pglib_opf_case240_pserc", "pglib_opf_case4619_goc", "pglib_opf_case24464_goc", "pglib_opf_case4661_sdet",
              "pglib_opf_case24_ieee_rts", "pglib_opf_case4837_goc", "pglib_opf_case2736sp_k", "pglib_opf_case4917_goc",
              "pglib_opf_case2737sop_k", "pglib_opf_case500_goc", "pglib_opf_case2742_goc", "pglib_opf_case5658_epigrids",
              "pglib_opf_case10000_goc", "pglib_opf_case2746wop_k", "pglib_opf_case57_ieee", "pglib_opf_case10192_epigrids",
              "pglib_opf_case2746wp_k", "pglib_opf_case588_sdet", "pglib_opf_case10480_goc", "pglib_opf_case2848_rte",
              "pglib_opf_case5_pjm", "pglib_opf_case118_ieee", "pglib_opf_case2853_sdet", "pglib_opf_case60_c",
              "pglib_opf_case1354_pegase", "pglib_opf_case2868_rte", "pglib_opf_case6468_rte", "pglib_opf_case13659_pegase",
              "pglib_opf_case2869_pegase", "pglib_opf_case6470_rte", "pglib_opf_case14_ieee", "pglib_opf_case30000_goc",
              "pglib_opf_case6495_rte", "pglib_opf_case162_ieee_dtc", "pglib_opf_case300_ieee", "pglib_opf_case6515_rte",
              "pglib_opf_case179_goc", "pglib_opf_case3012wp_k", "pglib_opf_case7336_epigrids", "pglib_opf_case1803_snem",
              "pglib_opf_case3022_goc", "pglib_opf_case73_ieee_rts", "pglib_opf_case1888_rte", "pglib_opf_case30_as",
              "pglib_opf_case78484_epigrids", "pglib_opf_case19402_goc", "pglib_opf_case30_ieee", "pglib_opf_case793_goc",
              "pglib_opf_case1951_rte", "pglib_opf_case3120sp_k", "pglib_opf_case8387_pegase", "pglib_opf_case197_snem",
              "pglib_opf_case3375wp_k", "pglib_opf_case89_pegase", "pglib_opf_case2000_goc", "pglib_opf_case3970_goc",
              "pglib_opf_case9241_pegase", "pglib_opf_case200_activ", "pglib_opf_case39_epri", "pglib_opf_case9591_goc",
              "pglib_opf_case20758_epigrids", "pglib_opf_case3_lmbd", "pglib_opf_case2312_goc", "pglib_opf_case4020_goc",
              "pglib_opf_case2383wp_k", "pglib_opf_case4601_goc")

for (name_benchmark, name_instances) in [("tax", name_tax), ("cops", name_cops), ("pglib", name_pglib), ("maxopf", name_pglib)]
  path_tex = joinpath(@__DIR__, "tex", "benchmarks_$(name_benchmark).tex")

  df = DataFrame(instance=String[], ipm=String[], kkt=String[], solver=String[], status=Int[],
                 timer=Float64[], pr=Float64[], dr=Float64[], pcr=Float64[], dcr=Float64[], mr=Float64[])

  for ipm in ("madnlp", "madncl", "hykkt", "likkt")
    for kkt in ("K2", "K2r", "K1s", "K1")
      for solver in ("ma27", "ma57", "cudss-ldl")
        benchmark_file = joinpath(results_dir, "$(name_benchmark)_$(ipm)_$(kkt)_$(solver).txt")
        if isfile(benchmark_file)
          data, header = readdlm(benchmark_file, '\t', header=true)
          m, n = size(data)
          @assert n == 13
          for k = 1:m  # m is the number of instances
            instance = data[k,1]
            solver = solver == "cudss-ldl" ? "cudss" : solver
            status = data[k,2]
            timer = data[k,5]
            pr = data[k,9]    # primal residual
            dr = data[k,10]   # dual residual
            pcr = data[k,11]  # primal complementarity residual
            dcr = data[k,12]  # dual complementarity residual
            mr = data[k,13]   # maximum residual
            results = (instance, ipm, kkt, solver, status, timer, pr, dr, pcr, dcr, mr)
            push!(df, results)
          end
        else
          for instance in name_instances
            benchmark_file = joinpath(results_dir, "$(instance)_$(ipm)_$(kkt)_$(solver).txt")
            if isfile(benchmark_file)
              data, header = readdlm(benchmark_file, '\t', header=true)
              m, n = size(data)
              @assert data[1,1] == instance
              @assert m == 1
              @assert n == 13
              solver = solver == "cudss-ldl" ? "cudss" : solver
              status = data[1, 2]
              timer = data[1, 5]
              pr = data[1, 9]   # primal residual
              dr = data[1,10]   # dual residual
              pcr = data[1,11]  # primal complementarity residual
              dcr = data[1,12]  # dual complementarity residual
              mr = data[1,13]   # maximum residual
              results = (instance, ipm, kkt, solver, status, timer, pr, dr, pcr, dcr, mr)
              push!(df, results)
            end
          end
        end
      end
    end
  end

  if !isempty(df)
    open(path_tex, "w") do io
      pretty_latex_stats(io, df)
    end

    text = read(path_tex, String)
    text = "\\documentclass{article}\n\\usepackage{longtable}\n" *
           "\\usepackage{pdflscape}\n\\usepackage{nopageno}\n" *
           "\\begin{document}\n\\begin{landscape}\n" * text
    text = text * "\\end{landscape}\n\\end{document}"
    write(path_tex, text)
  end
end
