function Normalise_limitDynamicRange_ISAR_dB = Normalise_limitDynamicRange_ISAR_dB(ISAR_image_complex_linear, dynamic_range)
%NORMALISE_LIMITDYNAMICRANGE_ISAR_DB  Normalise an ISAR image to dB for display.
%
%   Normalises the image so the strongest response is 0 dB and limits the
%   displayed dynamic range to 'dynamic_range' dB below the peak.
%
%   Provided by Dr M. Y. Abdul Gaffar and used unmodified in this project.
%
%   ISAR_image_complex_linear : complex ISAR image (linear)
%   dynamic_range             : dynamic range in dB below the peak

      ISAR_image_complex_linear = abs(ISAR_image_complex_linear)./max(max(abs(ISAR_image_complex_linear)));
      ISAR_image_dB = 20*log10(abs(ISAR_image_complex_linear));
      max_value_inplot = max(max(ISAR_image_dB));
      indx = find(ISAR_image_dB < (max_value_inplot-dynamic_range));
      ISAR_image_dB(indx) = (max_value_inplot-dynamic_range);
      ISAR_image_dB =  ISAR_image_dB - max_value_inplot;
      
      Normalise_limitDynamicRange_ISAR_dB = ISAR_image_dB;