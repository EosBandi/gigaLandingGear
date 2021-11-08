--------------------------------------------------------------------------------
--         FILE:  landing_legs.lua
--        USAGE:  Copy to AP script folder
--  DESCRIPTION:  Controls the landing gear brushed ESC's. Input is the AP landing gear servo output, and sends
--				  pwm output for the SERVO_LEG_OUTPUT channel. LEG_UP_TIME and LEG_DOWN_TIME controls the time of deploy
--				  and retract.
-- REQUIREMENTS:  Enabled scripting with at least 64K memory allocated
--         BUGS:  ---
--        NOTES:  ---
--       AUTHOR:  Andras Schaffer, @Eosbandi, andras.schaffer@rotorsandcams.com
--      COMPANY:  Rotors and Cams Plc.
--      VERSION:  1.0
--      CREATED:  2021.10.08
--     REVISION:  ---
--------------------------------------------------------------------------------
-- Settings. Time is in ms, SERVO_LEG_CONTROL is function 29(Landing gear)
--			 SERVO_LEG_OUTPUT is servo channel
--			 UP and DOWN PWM is for motor control values


local LEG_UP_TIME = 5000     --leg up time in seconds
local LEG_DOWN_TIME = 5000   --leg down time in seconds

local SERVO_LEG_CONTROL = 29   -- Landing gear function 
local SERVO_LEG_OUTPUT  = 6   -- PWM Channel which connected to the servo brushed ESC's

local PWM_UP = 1000
local PWM_DOWN = 2000
local PWM_NEUTRAL = 1500


-- leg status
local LEG_DOWN = 0
local LEG_UP = 1
local LEG_TRANSIT_UP = 2
local LEG_TRANSIT_DOWN = 3

local leg_status = LEG_DOWN

-- 
local transit_start_time = 0
local transit_time = 0

local LEG_COMMAND_UP = 0
local LEG_COMMAND_DOWN = 1

local leg_command  = LEG_COMMAND_DOWN
local last_leg_command = LEG_COMMAND_DOWN

-- set center for leg_output
SRV_Channels:set_output_pwm_chan(SERVO_LEG_OUTPUT,PWM_NEUTRAL)

function update()

    -- check for leg command
    leg_command_pwm = SRV_Channels:get_output_pwm(SERVO_LEG_CONTROL)
    if (leg_command_pwm >=1800) then
        leg_command = LEG_COMMAND_DOWN
    else
        leg_command = LEG_COMMAND_UP
    end

    -- check input switch and start leg transition
    if (leg_command ~= last_leg_command) then
        if (leg_command == LEG_COMMAND_UP) then
            leg_status = LEG_TRANSIT_UP
            
            if (transit_start_time == 0) then
                transit_time = LEG_UP_TIME
            else
                transit_time = millis() - transit_start_time
            end
            transit_start_time = millis()
            SRV_Channels:set_output_pwm_chan(SERVO_LEG_OUTPUT,PWM_UP)  -- set to up
        else
            leg_status = LEG_TRANSIT_DOWN
            
            if (transit_start_time == 0) then
                transit_time = LEG_DOWN_TIME
            else
                transit_time = millis() - transit_start_time
            end
            transit_start_time = millis()

            SRV_Channels:set_output_pwm_chan(SERVO_LEG_OUTPUT,PWM_DOWN)  -- set to down
        end
		last_leg_command = leg_command
    end

    -- do the transition
	if (transit_start_time > 0) then
	
    if (transit_start_time + transit_time <= millis()) then
        -- transition finished
        transit_start_time = 0;
        SRV_Channels:set_output_pwm_chan(SERVO_LEG_OUTPUT,PWM_NEUTRAL)  -- set to neutral
        if (leg_status == LEG_TRANSIT_UP) then
            leg_status = LEG_UP
        end
        if (leg_status == LEG_TRANSIT_DOWN) then
            leg_status = LEG_DOWN
        end
    end
end

    return update, 250 -- reschedule the loop
end
gcs:send_text(6, "landing_gear.lua is running")
-- Start the loop
return update()