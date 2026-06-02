function generate_inp_simple_structure(template_file, output_file, elelist, K_values, E_values, nu_values)
%GENERATE_INP_SIMPLE_STRUCTURE Generate an Abaqus input file with binned permeability fields.
%
% This helper is provided for compatibility with test_inp_generation_auto.m.
% For templates that do not contain a full Part/Assembly structure, the current
% implementation uses the optimized permeability-assignment routine as a safe
% fallback. For highly customized Abaqus templates, users should adapt the
% insertion locations in generate_inp_with_permeability_optimized.m.

if nargin < 6
    error('generate_inp_simple_structure requires template_file, output_file, elelist, K_values, E_values, and nu_values.');
end

generate_inp_with_permeability_optimized(template_file, output_file, elelist, K_values, E_values, nu_values);
end
