function I = compute_integral(f,V,T)

% % % % % % %
% f: the function to integrate
% V: vertices (each row has x and y coordinates)
% T: triangulation (each row gives the indices of the vertices)

x = V(:,1); % extract x and y coordinates of all nodes 
y = V(:,2);
I=0;
p = size(T,1); 

for i = 1:p
% start accumulator at 0
% get number of triangles
% loop through the triangles
x1 = x(T(i,1));
x2 = x(T(i,2));
x3 = x(T(i,3));
y1 = y(T(i,1));
y2 = y(T(i,2));
y3 = y(T(i,3));
A = .5*abs(det([x1, x2, x3; y1, y2, y3; 1, 1, 1])); %find area 
z1 = f(T(i,1),:); % find values at the three corners
z2 = f(T(i,2),:);
z3 = f(T(i,3),:);
zavg = (z1 + z2 + z3)/3; % average the values 
I = I + zavg*A; % accumulate integral
% find coordinates of the three corners
end
    