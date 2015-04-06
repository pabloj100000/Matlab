function [square] = align()
% FUNCTION [square] = align()
%
% Simple function used to align the stimulus monitor with the Hidens array.
%
% Controls
% --------
%
% The function draws a single square centered on the screen. Use the arrow
% keys to change the shape of the square.
%
% UP 		- increase the vertical size of the square.
% DOWN 		- decrease the vertical size of the square.
% RIGHT 	- increase the horizontal size of the square.
% LEFT		- decrease the horizontal size of the square.
%
% Normally, these keys increment the square size by 1 pixel. Hold down the
% SHIFT key to increase this increment to 10 pixels.
%
% Though it should not be needed, you can also manipulate the square's center,
% using the following keys.
%
% J - Move the center left.
% L - Move the center right.
% K - Move the center down.
% I - Move the center up.
%
% The SHIFT modifier applies to these keys as well.
%
% The square may be reset to its original position by pressing the 'r' key.
%
% When you are satisifed with your square, press ESC to quit and return the
% current square size and position.
%
% Output
% ------
%
% The final square is returned, as [left, top, right, bottom];
%
% (C) 2015 Benjamin Naecker bnaecker@stanford.edu
% 04 Feb 2015 - wrote it

ex = initexptstruct();
ex = initkb(ex);
ex.disp.bgcol = 0;
ex = initdisp(ex);
ex = setup_keyboard(ex);
ex = do_alignment(ex);
square = ex.stim.square;

end

function ex = setup_keyboard(ex)
	ex.key.left_arrow = KbName('LeftArrow');
	ex.key.right_arrow = KbName('RightArrow');
	ex.key.up_arrow = KbName('UpArrow');
	ex.key.down_arrow = KbName('DownArrow');
	ex.key.left_shift = KbName('LeftShift');
	ex.key.right_shift = KbName('RightShift');
	ex.key.j = KbName('j');
	ex.key.k = KbName('k');
	ex.key.l = KbName('l');
	ex.key.i = KbName('i');
	ex.key.r = KbName('r');
end

function ex = do_alignment(ex)
	try
		ex.stim = struct();

		% Make a square centered on the screen
		ex.stim.square_center = ex.disp.winctr;
		ex.stim.square_size = 512;
		ex.stim.vert_size = ex.stim.square_size;
		ex.stim.horiz_size = ex.stim.square_size;
		ex.stim.square = [0 0 ex.stim.horiz_size ex.stim.vert_size];
		ex.stim.square = CenterRectOnPoint(ex.stim.square, ...
			ex.stim.square_center(1), ex.stim.square_center(2));

		% Compute a flash frequency
		ex.stim.flash_frequency = 1; 	% Hz
		ex.stim.inter_flash_interval = (1 / ex.stim.flash_frequency);
		fprintf('Inter-flash interval: %0.2f\n', ex.stim.inter_flash_interval);

		% Draw, and adjust size accordingly

		start_time = GetSecs();
		color = 0;

		while ~ex.key.keycode(ex.key.esc)

			% Get any key presses
			ex = checkkb(ex);

			% Compute square's color
			if (mod(round((GetSecs() - start_time) / ...
				ex.stim.inter_flash_interval), 2) == 0)
				color = 1;
			else
				color = 0;
			end

			% First check for reset
			if ex.key.keycode(ex.key.r)
				ex.stim.square_center = ex.disp.winctr;
				ex.stim.horiz_size = ex.stim.square_size;
				ex.stim.vert_size = ex.stim.square_size;
			else

				% Check shift for increment modifier
				if (ex.key.keycode(ex.key.left_shift) || ex.key.keycode(ex.key.right_shift))
					increment = 10;
				else
					increment = 1;
				end

				% Check arrows for changing square size
				if ex.key.keycode(ex.key.left_arrow)
					ex.stim.horiz_size = ex.stim.horiz_size - increment;
				elseif ex.key.keycode(ex.key.right_arrow)
					ex.stim.horiz_size = ex.stim.horiz_size + increment;
				elseif ex.key.keycode(ex.key.up_arrow)
					ex.stim.vert_size = ex.stim.vert_size + increment;
				elseif ex.key.keycode(ex.key.down_arrow)
					ex.stim.vert_size = ex.stim.vert_size - increment;
				end

				% Check JKLI for moving square center
				if ex.key.keycode(ex.key.j)
					ex.stim.square_center(1) = ex.stim.square_center(1) - increment;
				elseif ex.key.keycode(ex.key.l)
					ex.stim.square_center(1) = ex.stim.square_center(1) + increment;
				elseif ex.key.keycode(ex.key.k)
					ex.stim.square_center(2) = ex.stim.square_center(2) + increment;
				elseif ex.key.keycode(ex.key.i)
					ex.stim.square_center(2) = ex.stim.square_center(2) - increment;
				end
			end

			% Reposition square and draw
			ex.stim.square = [0 0 ex.stim.horiz_size ex.stim.vert_size];
			ex.stim.square = CenterRectOnPoint(ex.stim.square, ...
				ex.stim.square_center(1), ex.stim.square_center(2));
			Screen('FillRect', ex.disp.winptr, ex.disp.white * color, ex.stim.square);
			Screen('Flip', ex.disp.winptr);
		end

		Screen('CloseAll');
		ListenChar(0);
		fprintf(1, '\n\nSquare position:\n  vert: %d\n  horiz: %d', ...
			ex.stim.square_center);
		fprintf(1, '\n\nSquare size:\n  vert: %d\n  horiz: %d\n\n', ...
			ex.stim.vert_size, ex.stim.horiz_size);
	catch me
		disp(me);
		Screen('CloseAll');
		ListenChar(0);
	end
end
