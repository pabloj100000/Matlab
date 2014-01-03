%use daqhwinfo to get device name.

function WaitForRec()

ai = analoginput('nidaq','Dev1');
ai.InputType = 'SingleEnded';
addchannel(ai,0,'TrigChan');
ai.TrigChan.InputRange = [-10 10];
set(ai,'SampleRate',10000)
set(ai,'TriggerChannel',ai.Channel(1))
%set(ai,'TriggerType','HwDigital')
set(ai,'TriggerType','HwAnalogChannel')
%set(ai,'TriggerCondition','PositiveEdge')
set(ai,'TriggerCondition','AboveHighLevel')
%set(ai,'SamplesPerTrigger',1000)
set(ai,'TriggerConditionValue',1)
ai.TriggerFcn = @startRec;
start(ai)
wait(ai,60)
delete(ai)
clear ai

end

function startRec(obj,event)
	stop(obj);
end