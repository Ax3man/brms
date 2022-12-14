  /* scale and correlate time-series residuals
   * using the Cholesky factor of the correlation matrix
   * Args:
   *   zerr: standardized and independent residuals
   *   sderr: standard deviation of the residuals
   *   chol_cor: cholesky factor of the correlation matrix
   *   nobs: number of observations in each group
   *   begin: the first observation in each group
   *   end: the last observation in each group
   * Returns:
   *   vector of scaled and correlated residuals
   */
   vector scale_time_err(vector zerr, real sderr, matrix chol_cor,
                         int[] nobs, int[] begin, int[] end) {
     vector[rows(zerr)] err;
     for (i in 1:size(nobs)) {
       matrix[nobs[i], nobs[i]] L_i;
       L_i = sderr * chol_cor[1:nobs[i], 1:nobs[i]];
       err[begin[i]:end[i]] = L_i * zerr[begin[i]:end[i]];
     }
     return err;
   }
  /* scale and correlate time-series residuals
   * allowx for flexible correlation matrix subsets
   * Deviating Args:
   *   Jtime: array of time indices per group
   * Returns:
   *   vector of scaled and correlated residuals
   */
   vector scale_time_err_flex(vector zerr, real sderr, matrix chol_cor,
                              int[] nobs, int[] begin, int[] end, int[,] Jtime) {
     vector[rows(zerr)] err;
     int I = size(nobs);
     int has_err[I] = rep_array(0, I);
     int i = 1;
     matrix[rows(chol_cor), cols(chol_cor)] Cor;
     Cor = multiply_lower_tri_self_transpose(chol_cor);
     while (sum(has_err) != I) {
       int iobs[nobs[i]] = Jtime[i, 1:nobs[i]];
       matrix[nobs[i], nobs[i]] L_i;
       if (is_equal(iobs, sequence(1, rows(chol_cor)))) {
         // all timepoints are present in this group
         L_i = chol_cor;
       } else {
         // arbitrary subsets cannot be taken on chol_cor directly
         L_i = cholesky_decompose(Cor[iobs, iobs]);
       }
       L_i = sderr * L_i;
       err[begin[i]:end[i]] = L_i * zerr[begin[i]:end[i]];
       // find all additional groups where we have the same timepoints
       for (j in (i+1):I) {
         if (has_err[j] == 0 && is_equal(Jtime[j], Jtime[i]) == 1) {
           err[begin[j]:end[j]] = L_i * zerr[begin[j]:end[j]];
         }
       }
       while (has_err[i] == 1 && i != I) {
         i += 1;
       }
    }
    return err;
  }
