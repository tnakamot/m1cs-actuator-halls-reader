% M1CS_Read_Halls.m
%
% Author: Chris Carter, Takashi Nakamoto
% Email: ccarter@tmt.org, tnakamoto@tmt.org
% Revision Date: 11th June 2024
% Version: 1.2
%
% VERSION NOTES:
%
% V1.0 - Reads M1CS Actuator Hall Sensor board voltage outputs and computes
% position displacement. Plots live curves of Hall output voltages and
% position displacement.
%
% V1.1 - Acquires only the number of samples defined by the 'nsamples'
% variable. At termination, the data, as presented in the generated
% Figures, are automatically saved to a file.
%
% V1.2 - Removed the plots for faster execution. Shows statistics
% at the end of execution. Use atan2 instead of atan. Added 2*pi
% depending on argument of atan2 so that the calculated positions
% becomes continuous over the travel range of the offloader. Also,
% added subtracted pi for offloader and snubber so that the calculated
% position looks similar to the examples in the functional test procedure.
%
% INSTALLATION NOTES:
%
% This script requires the LabJack LJM Library which, amongst other things,
% enables communication between MATLAB and the LabJack T4 data acquisition
% unit.
%
% The LabJack LJM Library is introduced here: https://labjack.com/ljm
% The MATLAB LJM Library is available here: https://labjack.com/support/software/examples/ljm/matlab
%
% The MATLAB LJM Library should be unpacked and stored in a location on the
% machine running the script, and added to the MATLAB PATH.
%
% Script has been shown to work with a LabJack T4 and MATLAB Version
% R2023a.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set up the MATLAB environment

clear all % Clear previous environment variables and functions
close all; % Close previous Figures

% Definitions

% From MMCs position calculation recipe
k = 10/1.95; % Units: mm
V_0 = 1.6316; % Units: Volts

% Some variable declarations

nsamples = 100; % Number of samples to record
count = 0;
time = [0];

AIN0_vector = [0];
AIN1_vector = [0];

% Make the LJM .NET assembly visible
ljmAsm = NET.addAssembly('LabJack.LJM');

% Creating an object to nested class LabJack.LJM.CONSTANTS

t = ljmAsm.AssemblyHandle.GetType('LabJack.LJM+CONSTANTS');
LJM_CONSTANTS = System.Activator.CreateInstance(t);

handle = 0;

try
    % Open any LabJack device, using any connection, with any identifier
    [ljmError, handle] = LabJack.LJM.OpenS('ANY', 'ANY', 'ANY', handle);

    % Set up and call eReadName() to read the Analogue Input(s)
    for loop = 1:nsamples

        [ljmError, AIN0_val] = LabJack.LJM.eReadName(handle, 'AIN0', 0);
        [ljmError, AIN1_val] = LabJack.LJM.eReadName(handle, 'AIN1', 0);

        count = count + 1;
        time(count) = count;

        AIN0_vector(count) = AIN0_val;
        AIN1_vector(count) = AIN1_val;
    end
catch e
    disp(e)
    LabJack.LJM.CloseAll();
    return
end

try
    % Close handle to LabJack device

    LabJack.LJM.Close(handle);
catch e
    disp(e)
end

% Take statistics and calculate position in millimeters
V_1 = mean(AIN0_vector);
V_2 = mean(AIN1_vector);
if V_2 - V_0 > 0
    rollover = 0;
else
    rollover = 2 * pi;
end
POS = k * (atan2(V_2 - V_0, V_1 - V_0) + pi/4 - pi + rollover);
POS_os = k * (atan2(V_2 - V_0, V_1 - V_0) + pi/4);

fprintf("V0 : %5.3f V\n", V_0);
fprintf("Number of sapmles: %d\n", nsamples);
fprintf("V1 : %5.3f V (avg), %6.4f V (stdev)\n", V_1, std(AIN0_vector));
fprintf("V2 : %5.3f V (avg), %6.4f V (stdev)\n", V_2, std(AIN1_vector));
fprintf("Position (offloader, snubber): %6.3f mm\n", POS);
fprintf("Position (output shaft): %6.3f mm\n", POS_os);

% End of file
