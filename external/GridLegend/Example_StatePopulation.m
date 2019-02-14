function Example_StatePopulation(N)
% EXAMPLE_STATEPOPULATION State population example for GRIDLEGEND
%   EXAMPLE_STATEPOPULATION Plot the populations of several US states with
%   linear and exponential fits of the populations. The user then creates
%   the gridlegend.
%
%   EXAMPLE_STATEPOPULATION(N) Plot the populations and fits of several US
%   states and run example N (see below).
%
% EXAMPLES
%   Example 1: Create a regular legend to show why gridlegend is useful.
%
%   Example 2: Create a gridlegend using the default arrangement of legend
%   entries. By default, gridlegend creates legend entries in the order in
%   which they were plotted, filling down the columns first and then across
%   the rows.
%
%   Example 3: Create a gridlegend using a user-specified arrangement of
%   legend entries. The layout of the legend entries will correspond to the
%   layout of the object handles in the 2D array handles.
%
%   Example 4: Set gridlegend properties using name-value inputs.
%
%   Example 5: Set gridlegend properties using a structure.
%
%   Example 6: Create a gridlegend with some entries missing using a 2D
%   handles array with missing entries given by a graphics handle
%   placeholder.
%
% See also GRIDLEGEND

% Copyright 2018 Shane Lympany

% Version   | Date          | Notes
% ----------|---------------|----------------------------------------------
% 1.0       | 12 Mar 2018   | * Original release

% Step 1: Create a numeric array of the populations of several US states from 1870-2010
% Note: The rows of Population correspond to the Year
% Note: The columns of Population correspond to the States

States = {'Georgia','Michigan','North Carolina','New Jersey','Virginia'};
Abbrev = {'GA','MI','NC','NJ','VA'};
Year = (1870:10:2010)';
Population = [
  1184109     1184059     1071361      906096     1225163
  1542180     1636937     1399750     1131116     1512565
  1837353     2093889     1617947     1444933     1655980
  2216331     2420982     1893810     1883669     1854184
  2609121     2810173     2206287     2537167     2061612
  2895832     3668412     2559123     3155900     2309187
  2908506     4842325     3170276     4041334     2421851
  3123723     5256106     3571623     4160165     2677773
  3444578     6371766     4061929     4835329     3318680
  3943116     7823194     4556155     6066782     3966949
  4589575     8875083     5082059     7168164     4648494
  5463105     9262078     5881766     7364823     5346818
  6478216     9295297     6628637     7730188     6187358
  8186453     9938444     8049313     8414350     7078515
  9687653     9883640     9535483     8791894     8001024
  ];

% Step 2: Fit the population of each state using a linear fit and an exponential fit
% Note: These are not the best fits, but they are used to demonstrate GRIDLEGEND

LinearCoef = zeros(2,length(States));
ExpCoef = zeros(2,length(States));
for n = 1:length(States)
    LinearCoef(:,n) = polyfit(Year,Population(:,n),1)';
    ExpCoef(:,n) = polyfit(Year,log(Population(:,n)),1)';
end
LinearFit = repmat(LinearCoef(2,:),length(Year),1) + Year * LinearCoef(1,:);
ExpFit = repmat(exp(ExpCoef(2,:)),length(Year),1) .* exp(Year * ExpCoef(1,:));

% Step 3: Plot the population, linear fit, and exponential fit for each state

colors = [
    0 0 1
    1 0 0
    0 0.75 0
    0.5 0 0.5
    1 0.5 0
    ];
symbols = 'so^vx';
figure; hold on; box on;
handles = gobjects(length(States),3);
for n = 1:length(States)
    handles(n,1) = plot(Year,Population(:,n)/1e6,symbols(n),'Color',colors(n,:),'MarkerFaceColor',colors(n,:));
    handles(n,2) = plot(Year,LinearFit(:,n)/1e6,'--','Color',colors(n,:));
    handles(n,3) = plot(Year,ExpFit(:,n)/1e6,'-','Color',colors(n,:));
end
xlabel('Year'); ylabel('Population (Millions)');

% Example 1: Create a regular legend to show why gridlegend is useful.
if nargin > 0 && N == 1
    Categories = {'Population','Linear Fit','Exponential Fit'};
    Names = cell(1,length(States)*3);
    for n = 1:length(States)
        Names(3*(n-1)+1:3*n) = strcat(Abbrev(n),{', '},Categories);
    end
    legend(Names,'Location','EastOutside');
end

% Example 2: Create a gridlegend using the default arrangement of legend
% entries. By default, gridlegend creates legend entries in the order in
% which they were plotted, filling down the columns first and then across
% the rows.
if nargin > 0 && N == 2
    RowNames = {'Population','Linear Fit','Exponential Fit'};
    ColumnNames = Abbrev;
    gridlegend(RowNames,ColumnNames,'Location','NorthOutside');
end

% Example 3: Create a gridlegend using a user-specified arrangement of
% legend entries. The layout of the legend entries will correspond to the
% layout of the object handles in the 2D array handles.
if nargin > 0 && N == 3
    RowNames = Abbrev;
    ColumnNames = {'Population','Linear Fit','Exponential Fit'};
    gridlegend(handles,RowNames,ColumnNames,'Location','NorthWest');
end

% Example 4: Set gridlegend properties using name-value inputs.
if nargin > 0 && N == 4
    RowNames = States;
    ColumnNames = {'Population','Linear Fit','Exponential Fit'};
    gridlegend(handles,RowNames,ColumnNames,...
      'Alignment',{'r','c','c','c'},...
      'Location','NorthWest',...
      'Box','off',...
      'FontName','Times',...
      'FontSize',10,...
      'FontWeight','bold');
end

% Example 5: Set gridlegend properties using a structure.
if nargin > 0 && N == 5
    RowNames = States;
    ColumnNames = {'Population','Linear Fit','Exponential Fit'};
    LegendOptions.Location = 'NorthWest';
    LegendOptions.Box = 'off';
    LegendOptions.FontSize = 9;
    gridlegend(handles,RowNames,ColumnNames,LegendOptions);
end

% Example 6: Create a gridlegend with some entries missing using a 2D
% handles array with missing entries given by a graphics handle
% placeholder.
if nargin > 0 && N == 6
    delete(handles(1,2)); handles(1,2) = gobjects(1); % delete Georgia linear fit
    delete(handles(2,3)); handles(2,3) = gobjects(1); % delete Michigan exponential fit
    delete(handles(3,2)); handles(3,2) = gobjects(1); % delete North Carolina linear fit
    delete(handles(4,3)); handles(4,3) = gobjects(1); % delete New Jersey exponential fit
    RowNames = Abbrev;
    ColumnNames = {'Population','Linear Fit','Exponential Fit'};
    LegendOptions.Location = 'NorthWest';
    LegendOptions.Box = 'on';
    LegendOptions.FontSize = 9;
    gridlegend(handles,RowNames,ColumnNames,LegendOptions);
end

end