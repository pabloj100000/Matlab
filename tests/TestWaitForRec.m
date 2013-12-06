function TestWaitForRec()

dio = digitalio('nidaq','Dev1');

addline(dio,0:3, 0,'out');
Add input lines ? Add two lines from port 1 to dio, and configure them for input.

addline(dio,0:1, 1,'in');
To display a summary of the digital I/O object, type:

dio

%display returns the following

Display Summary of DigitalIO (DIO) Object Using 'USB-6212'.

         Port Parameters:  Port 0 is port configurable for reading and writing.
                           Port 1 is port configurable for reading and writing.
                           Port 2 is port configurable for reading and writing.
                           
           Engine status:  Engine not required.

DIO object contains line(s):

   Index:  LineName:  HwLine:  Port:  Direction:  
   1       ''         0        0      'Out'       
   2       ''         1        0      'Out'       
   3       ''         2        0      'Out'       
   4       ''         3        0      'Out'       
   5       ''         0        1      'In'        
   6       ''         1        1      'In'        
Write values ? Create an array of output values, and write the values to the digital I/O subsystem. Note that reading and writing digital I/O line values typically does not require that you configure specific property values.

pval = [1 1 0 1];
putvalue(dio.Line(1:4),pval)
Read values? To read only the input lines, type:

gval = getvalue(dio.Line(5:6))

%input lines values displayed
gval =
     0     0
To read both input and output lines, type:

gval = getvalue(dio)

%input and output lines values displayed
gval =
     1     1     0     1     0     0
When you read output lines getvalue returns the most recently output value set by putvalue.

Clean up ? When you no longer need dio, you should remove it from memory and from the MATLAB workspace.

delete(dio)
clear dio
end