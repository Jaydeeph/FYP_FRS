%% Load Database of Faces.
% Loads the face database, whilst keeping its hierarchy order.
faceDatabase = imageSet('FaceDatabase', 'recursive');

% Checks if the database is empty or not. If its empty it tells the user
% to add face data to the database.
if isempty(faceDatabase)
    disp('The database for face is empty. Please add face data from "Add Person To Database".');
    pause(6);
    clear;
    clc;
    Facial_Recognition_System_Menu;
end

%% Extracts HOG (Histogram of Oriented Gradient) Feature For One Image, Getting It Ready For Training.

% Extracts HOG features from the first image. 
checkHOGFeatures = extractHOGFeatures(read(faceDatabase(1), 1));

% Gets the size of the variable to see what sizes of the variable.
findDimensionalityOfTheProblem = size(checkHOGFeatures);

% Gets the size of how big the HOG feature array is.
dimensionalityOfTheProblem = findDimensionalityOfTheProblem(1, 2);

%% Extracts HOG Features From All Face Images That's In The Database For Training Set.

% This is the variable that will keep track of all features extracted from every face image.
trainingFeatures = zeros(size(faceDatabase, 1) * faceDatabase(1).Count, dimensionalityOfTheProblem);
featureCount = 1;

% First for loop goes over all the folders in the database.
for i = 1:size(faceDatabase, 1)
    % Second for loop goes over all the face images in the folder.
    for j = 1:faceDatabase(i).Count
        
        % Extracts HOG Features for the current index image, and keeps it
        % in the trainingFeatures variable.
        trainingFeatures(featureCount, :) = extractHOGFeatures(read(faceDatabase(i), 1));
        
        % The training label is gathers the folder name. 
        % The folder name is the name of the person that face belongs to.
        % This keeps a track of which feature corresponds to which database.
        % As this will be fed to the classifier model that will be created.
        trainingLabels{featureCount} = faceDatabase(i).Description;
        
        featureCount = featureCount + 1;
    end
end

%% Create N Number of Class Classifier Using Fitcecoc. Where N = Number Of Person In Database.
% This is the classifier model acquired from training the face images.
% Here the ECOC training method is used to train the classifier.
% Only able to discriminate between the people in the database.
faceClassifier = fitcecoc(trainingFeatures, trainingLabels);

%% Asks user neccassary details to send email.
disp('If an intruder is detected. You will be emailed! Please enter your email details.');
emailAddress = input('Please enter the email address: ', 's');
emailPassword = input('Please enter the password for the email: ', 's');
disp('');

%% Create Needed Variables And Create And Initializing VideoPlayer Object:

% This is a classifier to detect faces.
faceDetector = vision.CascadeObjectDetector('FrontalFaceCART', 'MinSize', [150 150]);

% This will create a object variable that will give access to the camera.
camObj = webcam();
runLoop = true;
faceDetectedSpeechBoolean = false;
emailSent = false;

% This takes a picture from the camera, and then gets the size of the
% variable that contains the height and width of the frame.
videoFrame = snapshot(camObj);
frameSize = size(videoFrame);

% This creates the video player that will be used to show real-time video
% stream from the webcam object that was created above.
videoPlayer = vision.VideoPlayer('Position', [100 100 [frameSize(2), frameSize(1)]]);

step(videoPlayer, videoFrame);

%% The while loop runs until the videoplayer window is closed.
while runLoop
    % Acquires a frame from the webcam.
    videoFrame = snapshot(camObj);
    
    % Creates a grayscale image of the frame that was just acquired.
    videoFrameGray = rgb2gray(videoFrame);
    
    % Detects face in the frame.
    facebbox = step(faceDetector, videoFrameGray);
    
    % Acquires size of the variables to see if there is a person detected or not.
    fbboxSize = size(facebbox, 1);
    
    % If there is no person detected.
    if fbboxSize == 0
        
        % And the speech was recently spoken. Meaning the person went out
        % of the frame.
        if (faceDetectedSpeechBoolean)
            
            % Speaks.
            system(sprintf('say -v Alex  %s', 'Hey, where did he go.'));
            
            % Makes the boolean false, so it can talk again if face is detected.
            faceDetectedSpeechBoolean = false;
        end
        
        % If email was sent, then it sets boolean to false, so it can
        % send a new email for the new face that gets detected.
        if (emailSent)
            emailSent = false;
        end
    end

    % If fbboxSize is more than one, it means face(s) is/are detected.
    if fbboxSize == 1
        
        % Adds a square box and text on the frame saying "Face Detected" where the face is.
        videoFrame = insertObjectAnnotation(videoFrame, 'rectangle', ...
            facebbox, 'Face Detected', 'FontSize', 18, 'LineWidth', 5);

        % Checks if the speech was not already spoken.
        if ~(faceDetectedSpeechBoolean)

            % Then it says a face has been detected.
            system(sprintf('say -v Alex  %s', 'A face has been detected.'));
            
            % Makes the boolean true, so it doesnt speak on every loop.
            faceDetectedSpeechBoolean = true;
        end
        
        % Crops the image to size of box of the detected face..
        croppedToFace = imcrop(videoFrame, [facebbox(1) facebbox(2) facebbox(3) facebbox(4)]);
        
        % Resize's the image, so extracted HOG features are of same
        % array lenght from the database.
        faceToQuery = imresize(croppedToFace, [400 400]);
        
        % Extracts HOG features from the face image.
        faceHOGFeatues = extractHOGFeatures(faceToQuery);
        
        % Predicts who the person is, by looking for the HOG Features
        % against the classified model.
        personLabel = predict(faceClassifier, faceHOGFeatues);
        
        % Adds a text on top [10 10] (coordindates) of the frame
        % with the name of the person that was recognised.
        videoFrame = insertText(videoFrame, [10 10], personLabel, ...
                'FontSize', 18, 'BoxColor', 'green', 'BoxOpacity', 0.8, 'TextColor', 'white');
            
        %Checks if the email was sent or not.
        if ~(emailSent)
            
            setpref('Internet','SMTP_Server','smtp.gmail.com');
            
            setpref('Internet','E_mail', emailAddress);
            setpref('Internet','SMTP_Username', emailAddress);
            setpref('Internet','SMTP_Password', emailPassword);
            props = java.lang.System.getProperties;
            props.setProperty('mail.smtp.auth','true');
            props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
            props.setProperty('mail.smtp.socketFactory.port','465');
            
            textTitle = '[ALERT] Jays Facial Recognition System';
            textBody = strcat('The person ', ...
                personLabel, ...
                ' was caught sneaking into your room!');
            
            sendmail(emailAddress, textTitle, textBody)
            
            emailSent = true;
        end
    end
    
    % Adds the frame to the videplayer to show it real time.
    step(videoPlayer, videoFrame);
    
    % While loop will keep running until the video player is closed.
    runLoop = isOpen(videoPlayer);
end

% Once the video player is closed. It will display this message
% and take the user back to the main menu.
disp('Taking you back to the main menu.');
pause(6);
clear;
clc;
Facial_Recognition_System_Menu;