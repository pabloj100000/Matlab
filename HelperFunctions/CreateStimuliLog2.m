function CreateStimuliLog2()
    % send an e-mail with all files in StimLogList attached
    global StimLogList    
    
    % write the execution date and time in the e-mail
    messageBody = {['Experiment finished running on: ', datestr(clock), '\n']};
    
    mail = configureEmail();
    sendmail(mail, 'Experiment', messageBody, StimLogList)
end

