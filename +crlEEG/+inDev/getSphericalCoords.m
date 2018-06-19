%%

center = mean(elec.position,1);

relPos = elec.position - repmat(center,numel(elec),1);
relFIDPos = fid.position - repmat(center,numel(fid),1);

vecZ = fid('Cz').position - center; vecZ = vecZ./norm(vecZ);
vecX = fid('FidNz').position - center; vecX = vecX./norm(vecX);

vecX = vecX - vecZ*(vecZ*vecX'); vecX = vecX./norm(vecX);

vecY = cross(vecZ,vecX);

basis = [vecX(:) vecY(:) vecZ(:)];

newPos = (basis'*relPos')';

X = newPos(:,1); Y = newPos(:,2); Z = newPos(:,3);

r = sqrt(X.^2 + Y.^2 + Z.^2);
theta = acos(Z./r);
phi = atan(Y./X);
phi(X<0) = phi(X<0) + pi;

theta = (0.95/max(theta))*theta;
x = theta.*sin(phi);
y = theta.*cos(phi);


%%
figure;
theta = (0.95/max(theta))*theta;
drawHeadCartoon(gca);
x = theta.*sin(phi);
y = theta.*cos(phi);
%y(phi>pi/2) = -y(phi>pi/2);
%[x,y] = pol2cart(phi,theta);
scatter(x,y);
axis([-1.25 1.25 -1.25 1.25]);
