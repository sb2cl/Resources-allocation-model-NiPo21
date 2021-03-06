%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% Evaluation of the resources recruitment strengths (J_N_r, J_N_nr) at
% steady state  for the wild-type model 
%  
%  The function CostF_Mu_ss_wildtype has input arguments:
%       x = set of parameters kb_r, ku_r, kb_nr, ku_nr, omega_r, omega_nr
%       being optimized
%       r = profile r(mu) from the previous optimization iteration
%
%  and returns the cost index associated to the prediction error of the
%  growth rate
%  In this script we use the phenomenological relationship mp(mu) obtained
%  from thge experimental data:
%   m =m0exp(βμ)    m0=77.3748e−15(g)    β=61.7813(min)
%
%  WARNING: notice we use the subindexes p and nr interchangeably  to denote
%  non-ribosomal proteins
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [F] = CostF_Mu_ss_wildtype_mp_v6(x) 

global model_p;
global Bremer_exp_data;
ku_r = x(1,1);
ku_nr = x(1,2);
kb_r = x(1,3);
kb_nr = x(1,4);
Omega_r = x(1,5);
Omega_nr = x(1,6);
Phi_m_mod = x(1,7);

nu_t_exp = Bremer_exp_data.nu_t; % vector with nu_t for each mu
mu_exp =  Bremer_exp_data.mu;

ke_r= nu_t_exp/model_p.le_r;
ke_nr= nu_t_exp/model_p.le_nr;
KC0_r =kb_r./(ku_r+ ke_r);
KC0_nr =kb_nr./(ku_nr+ ke_nr);

while true 
    
if model_p.model_mass==1
 m0=77.3748e-15; %(g)  
  beta=61.7813; % (min)
 %mp_estimated = m0*exp(beta*mu_exp); % Notice that uses the experimental mu, not the estimated one
 mh_estimated = m0*exp(beta*model_p.mu_estimated); 
else
    m0=1.29181e-14;
    beta=	14.1089;
    gamma= 0.389004;
    %mp_estimated = m0*exp(beta*mu_exp.^gamma);
    mh_estimated = m0*exp(beta*model_p.mu_estimated.^gamma);
end

% We first estimate the flux mu*r of free resources:
     mu_r =  model_p.m_aa.*nu_t_exp.*mh_estimated.*(1-model_p.Phi_h_b)./model_p.Phi_h_t.*(Phi_m_mod.*model_p.Phi_r_t/model_p.ribosome_mass).^2;
     
  %Now we estimate the sums Nr*Jr, Np*Jp  and J_A

    JNr_estimated =  model_p.N_r*model_p.Em_r*Omega_r./(model_p.dm_r./KC0_r + mu_r);
    JNnr_estimated =  model_p.N_nr*model_p.Em_nr*Omega_nr./(model_p.dm_nr./KC0_nr + mu_r);

    JWSum = model_p.WEm_r*JNr_estimated + model_p.WEm_nr *JNnr_estimated;
    JSum = JNr_estimated+ JNnr_estimated;

     model_p.Phi_h_b = JWSum./(1+JWSum);
     model_p.Phi_r_t = JNr_estimated./(1+JWSum);  %Fraction of actively translating ribosomes w.r.t. mature available ones for ribosomal protein-coding genes
     model_p.Phi_nr_t = JNnr_estimated./(1+JWSum);  %Fraction of actively translating ribosomes w.r.t. mature available ones for non-ribosomal endogenous  protein-coding genes
     model_p.Phi_h_t =  model_p.Phi_r_t  + model_p.Phi_nr_t;
     
     % We update the estimate of the flux mu*r of free resources:
     factor = 1./JSum;
     mu_r_new =  model_p.m_aa.*nu_t_exp.*mh_estimated.*(Phi_m_mod.*model_p.Phi_r_t/model_p.ribosome_mass).^2.*factor;
     
      if sum(abs(mu_r_new - mu_r)) < 1e-3
        % We update the estimation of the cell growth rate:
        mu_estimated_profile = model_p.m_aa./model_p.ribosome_mass.*nu_t_exp.*Phi_m_mod.*model_p.Phi_r_t;
        model_p.mu_estimated = mu_estimated_profile;
        break;
    else
         mu_r = mu_r_new;
        mu_estimated_profile = model_p.m_aa./model_p.ribosome_mass.*nu_t_exp.*Phi_m_mod.*model_p.Phi_r_t;
        model_p.mu_estimated = mu_estimated_profile;
      end
      
end % while

% The cost function to be optimized is the sum of the absolute prediction
% errors between the experimental and the estimated growth rates:

F = sum(abs(mu_estimated_profile - mu_exp));

end

  



   
     
   
 
 
 