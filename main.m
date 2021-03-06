clc;
close all;
clear global;
clear all;
addpath '/home/church/visual_opt/modernrobotics/code/MATLAB'
addpath 'Share_Version'

[RobotPara, Slist_m, Mlist_m, Slist_f, Mlist_f] = structDVRK_TCM_roll();

rosshutdown
rosinit;
P = psm('PSM1');
T_dsr  = eye(4);

q(1) = 0;
q(2) = 0;
q(3) = 0.2;
q(4) = 0;
q(5) = 0;
q(6) = 0;
goal_reached = false;
while goal_reached == false
    goal_reached = P.move_joint(q);
    pause(0.5);
end
q_home = P.get_state_joint_current();
%
% global obj
% obj = webcam('USB2.0 PC CAMERA: USB2.0 PC CAM');
obj = webcam('USB camera: USB camera');
% obj = videoinput('linuxvideo', 1,'YUY2_640x480');
% preview(obj);
% triggerconfig(obj, 'manual');
% start(obj);

error=[];
ZUO=[];
TTTT=0;
% j = 1;
error1 = 10;
error2 = 10;
p_current = [0,0,-0.01]';
while 1
    %     u=600;
    %     v=600;
    
    [u,v]  = KK(error1, error2, p_current, obj);
    error1 = sqrt((u-640)^2);
    error2 = sqrt((v-360)^2);
    eomg = 1e-3;
    ev = 1e-3;
    
    O=1;
    while(sqrt(error1^2+error2^2) > 10)
%         tic
        %         u=310;
        %         v=235;
        [u,v]  = KK(error1,error2, p_current, obj);
        error1 = sqrt((u-640)^2);
        error2 = sqrt((v-360)^2);
%         tic
        uu=[u,v];
                ZUO=[ZUO;uu];
        [theta, phi]        = T(uu);
        
        thetalist_current   = P.get_state_joint_current();
        thetalist_current(1) = -thetalist_current(1);
        thetalist_current(2) = -thetalist_current(2);
        
        l4ml2               = -thetalist_current(5);
        l3ml1               = thetalist_current(6);
        [phi_cur,theta_cur] = Cable2Joint(l4ml2,l3ml1);
        thetalist_current(5)= phi_cur;
        thetalist_current(6)= theta_cur;
        
        
        %         [Slist,M,tlist,~]   = construct(thetalist_current);
        %         T_current           = FKinSpace_new(M,Slist,tlist);
        io                  = thetalist_current(3);
        roll                = thetalist_current(4);
        thetalist_current(3)= roll;
        thetalist_current(4)= io;
        T_current           = FKinSpace_DVRK_TCM(RobotPara, Mlist_m{end}, Slist_m, thetalist_current);
        
        
        p_current           = T_current(1:3,4);
        R_current           = T_current(1:3,1:3);
        eulZYX_marked       = rotm2eul( R_current );
        gamma               = eulZYX_marked(1);
%         x_cur               = p_current(1);
%         y_cur               = p_current(2);
%         z_cur               = p_current(3);
        
        R_dsr               = R_current* rotz((phi)*180/pi)*roty((theta/6)*180/pi)* rotz((-phi)*180/pi);
        
        %%%%%% Inner roll fixed added    %%%%%%%%%%%%%%%%%%%
        
        eulZYX              = rotm2eul( R_dsr );
        eulZYX(1)           = gamma;
        R_dsr               = eul2rotm( eulZYX );
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        T_dsr(1:3,1:3)      = R_dsr;
        T_dsr(1:3,4)        = p_current;
        [thetalist_solve, success] = IFK_DVRK_TCM_roll(RobotPara, Mlist_m, Slist_m, T_dsr, thetalist_current, eomg, ev);
        %    t =1;
        %    algorithm   = 'Numerical Inverse Kinematics';
        %    [q_act, cycle_hi, Jac_hist, dJac_hist, p_act, success]   = IKinSpace_new(T_dsr,thetalist_current,t,algorithm);
        % figure (4)
        % drawDVRK_TCM_roll(thetalist_current);
        % drawDVRK_TCM_roll(thetalist_solve);
        roll                = thetalist_solve(3);
        io                  = thetalist_solve(4);
        thetalist_solve(3)  = io;
        thetalist_solve(4)  = roll;
%         thetalist_solve;
        q_act               = thetalist_solve;
        cycle_hist(:,1)     = success;
        
        phi_act             = q_act(5);
        theta_act           = q_act(6);
        [l4ml2,l3ml1]       = Joint2Cable(phi_act,theta_act);
        
        l4ml2               = -l4ml2;
        q_act(5)            =  l4ml2;
        q_act(6)            =  l3ml1 ;
        q_act(1)            = -q_act(1)/2;
        q_act(2)            = -q_act(2)/2;
        
%         Q(:,j) = q_act;
%         j = j+1;
tic
        goal_reached = false;
        while goal_reached == false
            goal_reached = P.move_joint(q_act);
            pause(0.1);
        end
        
         O=O+1;
         error=[error;sqrt(error1^2+error2^2)];
         TTTT=[TTTT;toc];
%         ZUO;
        
    end

%     O;
%     TTTT;
end



