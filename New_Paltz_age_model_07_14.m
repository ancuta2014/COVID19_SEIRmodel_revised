function dx = New_Paltz_age_model_07_14(x,beta,Q)

dx=zeros(6,4);
N = sum(x(:));

  %mean incubation period
  lambda = 7;
  %percent of exposed people who are asymptomatic
  alpha = 0.1;
  %mean recovery period
  gamma = 10;
  %mean immunity period
  phi = 250;
  %mean window for active virus in A
  theta = 10;
  %fraction of R who develop limited immunity
  rho = 0.95;
  %death rate
  dmax = 0.05;
  d = [0.01*dmax 0.01*dmax 0.6*dmax 1*dmax];

%SE = number of all exposed individuals (of all ages) at location 
SE = sum(x(2,:),2);
%SI = number of all infected individuals (of all ages) at location
SA = sum(x(3,:),2);
SI = sum(x(4,:),2);
tau = (SI + Q*SE + Q*SA)/max(N,1);

    for age = 1:4
    %susceptible
    dx(1,age) = -beta(age)*x(1,age)*tau + (1/phi)*x(5,age) + (1-rho)*(x(4,age)*(1/gamma)*(1-d(age))+x(3,age)*(1/theta));
    %exposed, presymptomtic
    dx(2,age) = beta(age)*x(1,age)*tau*(1-alpha) - (1/lambda)*x(2,age);
    %exposed, asymptomatic
    dx(3,age) = beta(age)*x(1,age)*tau*(alpha) - x(3,age)*(1/theta);   
    %infected, symptomatic
    dx(4,age) = (1/lambda)*x(2,age) - x(4,age)*(1/gamma);
    %recovered, with immunity
    dx(5,age) = rho*(x(4,age)*(1/gamma)*(1-d(age))+x(3,age)*(1/theta))-x(5,age)*(1/phi);
    %deceased
    dx(6,age) = x(4,age)*(1/gamma)*d(age);
    end;
        
    end

