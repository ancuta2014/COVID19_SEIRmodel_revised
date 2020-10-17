%This program will distinguish AGE = 4 age groups; in order of the AGE
%index: children; young adults; adults; elderly;
AGES = 4;

%SEIR compartments
COMP = 6;

%Simulation will run for a number of days D;
D = 500;

%Individuals in this simulation are allowed to travel to one of 
%PLACES destinations each day; the destinations are listed below.
PLACES = 7;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Destinations, in order for of the PLACE index
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Doctor (everyone, mostly when sick);
%Shops, utilities (everyone);
%Church (elderly socials);
%University campus (young adults mostly);
%School (primarily kids);
%Park (kids entertainment);
%Bars, restaurants (adults entertainment).

%Damping rate for infection due to contact with exposed (not yet infected)
%individuals.
Q = 0.6; 

%Initializing working arrays, as described below.
B = zeros(PLACES,AGES);
B0 = zeros(AGES,1);
MV = zeros(PLACES,COMP,AGES);    
transit = zeros(D,COMP,AGES);
M = zeros(D,COMP,AGES);

%time spent at destination = steps * h
steps1 = 24; %integration steps at destination (equivalent of 6 hours)
steps2 = 72; %integration steps at home (equivalent of 18 hours)
h = .011; %Euler step size (equivalent of 15 mins)

%The state of the system each day (number of individuals in each
%compartment, in each age group), is recoreded in a vector y, of
%size: (number of days) x (SEIR compartments) x (age groups).
y = zeros(D,COMP,AGES);

%Initialize the state vector at the start of day one to 1000 susceptible 
%individuals in each age group, plus 2 additional exposed adults.
y(1,1:COMP,1:AGES) = [1000 1000 1000 1000; 0 0 2 0; 0 0 0 0; 0 0 0 0; 0 0 0 0; 0 0 0 0];
    

%Scalar constants defining the closure day for each destination, and 
%relaxation day for all closures.  
    bars = 20;
    stores = 1000;
    doctor = 1000;
    schools = 15;
    campus = 10;
    church = 30;
    relax = 1000;
    DDb = 2;
    
%At the start of each day, send specific fractions of each community out to disjoint
%destinations z1 and z2, 
for day = 1:D   
    
%Baseline infection rate when traveling outside of the home environment = b.
%This is then addapted multiplicatively according to age and location, and
%recorded in the array B (which can be changed each day). Every 7th day,
%the church infection rate spikes by a factor DD.
b = 0.1*3;
B = [b 2*b 2*b+DDb*b*(rem(day,7)==1) 2*b 2*b 2*b 3*b; b 1.5*b 1.5*b+DDb*b*(rem(day,7)==1) 1.5*b 1.5*b b 3*b; b 1.5*b 1.5*b+DDb*b*(rem(day,7)==1) 1.5*b 1.5*b b 3*b; b b b+DDb*b*(rem(day,7)==1) b b b 2*b;]';

%Baseline infection rate at home (within home environment, when not traveling) = b0 
%(set to be 80% reduced from the baseline infection rate outside of the home). 
%This rate can then be adapted according to different age groups, and can
%be changed in time.
b0 = 0.08*3;
B0 = b0*ones(AGES,1);

%Infection rate constant for all places and age groups;    
%DOCTOR,STORE,CHURCH,CAMPUS,SCHOOL,PARK,BARS    
Qr = [(day<doctor)||(day>relax) 1 (day<church)||(day>relax) (day<campus)||(day>relax) (day<schools)||(day>relax) 1 (day<bars)||(day>relax)];
quar = [Qr; Qr; Qr; Qr; Qr; Qr]; 

%Kids travel:
MVweek(1:PLACES,1:COMP,1) = [0.01 0.02 0.1 0 0.5 0.3 0; 0.01 0.02 0.1 0 0.5 0.3 0; 0.01 0.02 0.1 0 0.5 0.3 0; 0.2 0 0 0 0.2 0.1 0; 0 0 0 0 0 0 0; 0 0 0 0 0 0 0]';
%Young adult travel:
MVweek(1:PLACES,1:COMP,2) = [0.01 0.1 0.01 0.4 0.1 0.01 0.3; 0.01 0.1 0.01 0.4 0.1 0.01 0.3; 0.01 0.1 0.01 0.4 0.1 0.01 0.3; 0.2 0.1 0 0.2 0 0 0.2; 0 0 0 0 0 0 0; 0 0 0 0 0 0 0]';
%Adult travel:
MVweek(1:PLACES,1:COMP,3) = [0.02 0.15 0.15 0.15 0.1 0.15 0.2; 0.02 0.15 0.15 0.15 0.1 0.15 0.2; 0.02 0.15 0.1 0.15 0.1 0.15 0.2; 0.3 0.1 0.1 0.05 0.05 0 0.1; 0 0 0 0 0 0 0; 0 0 0 0 0 0 0]';
%Elderly travel:
MVweek(1:PLACES,1:COMP,4) = [0.1 0.2 0.3 0.05 0.05 0.2 0.05; 0.1 0.2 0.3 0.05 0.05 0.2 0.05; 0.1 0.2 0.3 0.05 0.05 0.2 0.05; 0.4 0.2 0.1 0 0 0 0; 0 0 0 0 0 0 0; 0 0 0 0 0 0 0]';
        
%Array describing mobility the seventh day of the week (church attendance)
Bchurch = 0.6;
MVchurch(1:PLACES,1:COMP) = [0 0 Bchurch 0 0 0 0; 0 0 Bchurch 0 0 0 0; 0 0 Bchurch 0 0 0 0; 0 0 Bchurch 0 0 0 0; 0 0 0 0 0 0 0; 0 0 0 0 0 0 0]';
    
%Kids travel:
MV(1:PLACES,1:COMP,1) = (rem(day,7)==1)*quar'.*MVchurch + (rem(day,7)~=1)*quar'.*MVweek(1:PLACES,1:COMP,1);
%Young adult travel:
MV(1:PLACES,1:COMP,2) = (rem(day,7)==1)*quar'.*MVchurch + (rem(day,7)~=1)*quar'.*MVweek(1:PLACES,1:COMP,2);
%Adult travel:
MV(1:PLACES,1:COMP,3) = (rem(day,7)==1)*quar'.*MVchurch + (rem(day,7)~=1)*quar'.*MVweek(1:PLACES,1:COMP,3);
%Elderly travel:
MV(1:PLACES,1:COMP,4) = (rem(day,7)==1)*quar'.*MVchurch + (rem(day,7)~=1)*quar'.*MVweek(1:PLACES,1:COMP,4);
        

%At the start of the day, we deploy individuals to each destination.
%The variables of each destination will be recorded in the array z.
        z = zeros(PLACES,COMP,AGES);
        for place = 1:PLACES
            z(place,:,:) = MV(place,:,:).*y(day,:,:);
        end
        
%The array "transit" records the total number of individuals deployed each
%day from each compartment and age group to all destinations combined
        for k = 1:COMP
            for age = 1:AGES
                transit(day,k,age) = sum(MV(:,k,age),1).*y(day,k,age);
            end
        end
           

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
%SEIR evolution at destinations (Euler method)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for place = 1:PLACES
    T = zeros(COMP,AGES,steps1);
    T(:,:,1) = z(place,:,:);
    for j = 1:steps1-1
          dT = New_Paltz_age_model_07_14(T(:,:,j),B(place,:),Q);
          for k = 1:COMP
             for age = 1:AGES
             T(k,age,j+1) = T(k,age,j) + h*dT(k,age);
             end
          end
    end
    z(place,:,:) = T(:,:,end);
 end
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Update home compartment to people left behind
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
M(day,:,:) = y(day,:,:) - transit(day,:,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%          
%SEIR evolutions at home, while transit people are traveling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    T = zeros(COMP,AGES,steps1);
    T(:,:,1) = M(day,:,:);
        for j = 1:steps1-1
                dT = New_Paltz_age_model_07_14(T(:,:,j),B0,Q);
                T(:,:,j+1) = T(:,:,j) + h*dT(:,:);
        end
    M(day,:,:) = T(:,:,end);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%People return, home compartments are updated accordingly
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
M(day,:,:) = M(day,:,:) + sum(z(:,:,:),1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%SEIR evolution at home, between travel to destinations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     T = zeros(COMP,AGES,steps2);
     T(:,:,1) = M(day,:,:);
        for j = 1:steps2-1
                dT = New_Paltz_age_model_07_14(T(:,:,j),B0,Q);
                T(:,:,j+1) = T(:,:,j) + h*dT(:,:);
        end
     y(day+1,:,:) = T(:,:,end);
       
end


%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Plotting overall evolution in each community by age
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   figure;
   set(gcf,'Position',[20 100 1200 240])
   hold on;
   
   subplot(1,4,1);
   hold on;
   plot(y(:,1,1),':b','Linewidth',1);
   plot(y(:,2,1),':m','Linewidth',1);
   plot(y(:,3,1),':c','Linewidth',1);
   plot(y(:,4,1),':r','Linewidth',1);
   plot(y(:,5,1),':g','Linewidth',1);
   plot(y(:,6,1),':k','Linewidth',1);
   title('Children');
   axis([0 500 0 1000])
   ax = gca;
   ax.FontName = 'Times New Roman';
   box on;
   subplot(1,4,2);
   hold on;
   plot(y(:,1,2),'--b','Linewidth',1);
   plot(y(:,2,2),'--m','Linewidth',1);
   plot(y(:,3,2),'--c','Linewidth',1);
   plot(y(:,4,2),'--r','Linewidth',1);
   plot(y(:,5,2),'--g','Linewidth',1);
   plot(y(:,6,2),'--k','Linewidth',1);
   title('Young adults');
   axis([0 500 0 1000])
   ax = gca;
   ax.FontName = 'Times New Roman';
   box on;
   subplot(1,4,3);
   hold on;
   plot(y(:,1,3),'b','Linewidth',1);
   plot(y(:,2,3),'m','Linewidth',1);
   plot(y(:,3,3),'c','Linewidth',1);
   plot(y(:,4,3),'r','Linewidth',1);
   plot(y(:,5,3),'g','Linewidth',1);
   plot(y(:,6,3),'k','Linewidth',1);
   title('Adults');
   axis([0 500 0 1000])
   ax = gca;
   ax.FontName = 'Times New Roman';
   box on;
   subplot(1,4,4);
   hold on;
   plot(y(:,1,4),'b','Linewidth',2);
   plot(y(:,2,4),'m','Linewidth',2);
   plot(y(:,3,4),'c','Linewidth',2);
   plot(y(:,4,4),'r','Linewidth',2);
   plot(y(:,5,4),'g','Linewidth',2);
   plot(y(:,6,4),'k','Linewidth',2);
   title('Elderly');
   axis([0 500 0 1000])
   ax = gca;
   ax.FontName = 'Times New Roman';
   box on;
  
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Plotting overall evolution in each community by compartment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   figure;
   set(gcf,'Position',[20 100 1200 240])
   hold on;
   
   subplot(1,6,1);
   hold on;
   plot(y(:,1,1),':b','Linewidth',1);
   plot(y(:,1,2),'--b','Linewidth',1);
   plot(y(:,1,3),'-b','Linewidth',1);
   plot(y(:,1,4),'b','Linewidth',2);
   title('Susceptible');
   axis([0 500 0 1000])
   ax = gca;
   ax.FontName = 'Times New Roman';
   xlabel('Time (in days)','FontSize',12)
   box on;
   subplot(1,6,2);
   hold on;
   plot(y(:,2,1),':m','Linewidth',1);
   plot(y(:,2,2),'--m','Linewidth',1);
   plot(y(:,2,3),'m','Linewidth',1);
   plot(y(:,2,4),'m','Linewidth',2);
   title('Presymptomatic');
   axis([0 500 0 300])
   ax = gca;
   ax.FontName = 'Times New Roman';
   xlabel('Time (in days)','FontSize',12)
   box on;
   subplot(1,6,3);
   hold on;
   plot(y(:,3,1),':c','Linewidth',1);
   plot(y(:,3,2),'--c','Linewidth',1);
   plot(y(:,3,3),'c','Linewidth',1);
   plot(y(:,3,4),'c','Linewidth',2);
   title('Asymptomatic');
   axis([0 500 0 150])
   ax = gca;
   ax.FontName = 'Times New Roman';
   xlabel('Time (in days)','FontSize',12)
   box on;
   subplot(1,6,4);
   hold on;
   plot(y(:,4,1),':r','Linewidth',1);
   plot(y(:,4,2),'--r','Linewidth',1);
   plot(y(:,4,3),'r','Linewidth',1);
   plot(y(:,4,4),'r','Linewidth',2);
   title('Infectious');
   axis([0 500 0 1000])
   ax = gca;
   ax.FontName = 'Times New Roman';
   box on;
   ax = gca;
   ax.FontName = 'Times New Roman';
   xlabel('Time (in days)','FontSize',12)
   subplot(1,6,5);
   hold on;
   plot(y(:,5,1),':g','Linewidth',1);
   plot(y(:,5,2),'--g','Linewidth',1);
   plot(y(:,5,3),'g','Linewidth',1);
   plot(y(:,5,4),'g','Linewidth',2);
   title('Recovered');
   axis([0 500 0 1000])
   ax = gca;
   ax.FontName = 'Times New Roman';
   box on;
   ax = gca;
   ax.FontName = 'Times New Roman';
   xlabel('Time (in days)','FontSize',12)
   subplot(1,6,6);
   hold on;
   plot(y(:,6,1),':k','Linewidth',1);
   plot(y(:,6,2),'--k','Linewidth',1);
   plot(y(:,6,3),'k','Linewidth',1);
   plot(y(:,6,4),'k','Linewidth',2);
   title('Fatalities');
   axis([0 500 0 1000])
   ax = gca;
   ax.FontName = 'Times New Roman';
   box on;
   ax = gca;
   ax.FontName = 'Times New Roman';
   xlabel('Time (in days)','FontSize',12)
   
  
   
   