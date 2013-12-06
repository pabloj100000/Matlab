function mail = configureEmail()
%   This is a dummy version, the original one has my real password and is
%   converted to pcode so that it will not be visible
%   Define these variables appropriately:
[mail password] = logindlg('', '');

% Then this code will set up the preferences properly:
setpref('Internet','E_mail',mail);
setpref('Internet','SMTP_Server','mail');
setpref('Internet','SMTP_Username',mail);
setpref('Internet','SMTP_Password',password);
props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
props.setProperty('mail.smtp.socketFactory.port','465');
end
