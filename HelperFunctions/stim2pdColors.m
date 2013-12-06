function pdColor = stim2pdColors(stim)
    Add2StimLogList();
    % Stim has to be a number < 4^4 = 255
    % stim2pdColors returns stim in 4 bits in base 4
    % stim = pdColor(1)*4^0 + pdColor(2)*4^1 + pdColor(2)*4^2 + pdColor(3)*4^3
    % pdColor(i) = {60, 120, 180, 240}
    pdBit0 = mod(stim, 4);
    pdBit1 = mod(floor((stim-pdBit0)/4),4);
    pdBit2 = mod(floor((stim-pdBit0)/16),4);
    pdBit3 = mod(floor((stim-pdBit0)/64),4);
    pdColor(1) = (pdBit0)*80+15;
    pdColor(2) = (pdBit1)*80+15;
    pdColor(3) = (pdBit2)*80+15;
    pdColor(4) = (pdBit3)*80+15;
end

