%% Display The Main Menu:
disp('"Recognise": To start detecting and Recognising a face.');
disp('"Add Face" : To add a person to the databse of faces.');
disp('"Quit"            : To quit the application');

%% Get Users' Input:
User_Answer = lower(input('Please choose from the following options: ', 's'));

%% Load The Correct MATLAB File Depending on User Input via Switch Cases.
switch User_Answer
    case 'recognise'
        clear;
        clc;
        Facial_Recognition_System;
    case 'add face'
        clear;
         clc;
        Add_Person_To_Database;
    case 'quit'
        clear;
        clc;
        
    otherwise
        clear;
        clc;
        Facial_Recognition_System;
end















