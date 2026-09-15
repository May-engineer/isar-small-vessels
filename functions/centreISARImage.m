
function ISAR_centred =  centreISARImage(ISAR_image, centreThreshold_dB)
% CENTREISARIMAGE Centre a target in an ISAR image.
%
%   [ISAR_centred, centreRow, centreCol, rowShift, colShift] =  centreISARImage(ISAR_image, centreThreshold_dB)
%
%   estimates the centre of the target using a power-weighted centroid of
%   the strongest pixels in the ISAR image. The image is then shifted so
%   that the estimated target centre lies at the middle range/Doppler bin.
%
%   INPUTS:
%       ISAR_image
%           Complex-valued ISAR image.
%
%       centreThreshold_dB
%           Pixels within this many dB of the peak are used to estimate
%           the target centre.
%
%           Example:
%               centreThreshold_dB = 15;
%
%   OUTPUTS:
%       ISAR_centred
%           Centred ISAR image.
%
%       centreRow
%           Estimated Doppler-bin centre of the target before shifting.
%
%       centreCol
%           Estimated range-bin centre of the target before shifting.
%
%       rowShift
%           Number of Doppler bins by which the image was shifted.
%
%       colShift
%           Number of range bins by which the image was shifted.
%
%   The shift uses zero padding rather than circular shifting. This avoids
%   energy leaving one edge of the ISAR image and reappearing at the
%   opposite edge.

    %% Determine image dimensions
    [numRows, numCols] = size(ISAR_image);

    %% Calculate ISAR image power
    ISAR_power = abs(ISAR_image).^2;

    %% Convert power to dB
    ISAR_dB = 20*log10(ISAR_power);

    %% Find peak level
    peak_dB = max(ISAR_dB(:));

    %% Select strong target pixels
    %
    % Only pixels lying within centreThreshold_dB of the peak are used.
    % This reduces the influence of weak clutter and background noise.
    strongMask = ISAR_dB >= (peak_dB - centreThreshold_dB);

    %% Power weighting
    weights = ISAR_power .* strongMask;

    %% Generate row and column coordinates
    [rowGrid, colGrid] = ndgrid(1:numRows, 1:numCols);

    totalWeight = sum(weights(:));

    %% Estimate target centre using a power-weighted centroid
    if totalWeight > 0

        centreRow = round(sum(rowGrid(:) .* weights(:)) / totalWeight);

        centreCol = round(sum(colGrid(:) .* weights(:)) / totalWeight);

    else

        % Fallback: use location of strongest pixel
        [~, maxIndex] = max(ISAR_power(:));

        [centreRow, centreCol] = ind2sub(size(ISAR_power), maxIndex);

    end

    %% Desired centre of ISAR image
    desiredCentreRow = floor(numRows/2) + 1;
    desiredCentreCol = floor(numCols/2) + 1;

    %% Determine required integer shift
    rowShift = desiredCentreRow - centreRow;
    colShift = desiredCentreCol - centreCol;

    %% Shift image with circular wrap-around
   ISAR_centred = circshift(ISAR_image, [rowShift, colShift]);

end

