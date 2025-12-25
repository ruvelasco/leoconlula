/**
 * Middleware to require specific roles
 */
export const requireRole = (...allowedRoles) => {
    return (req, res, next) => {
        if (!req.user) {
            res.status(401).json({ error: 'No autenticado' });
            return;
        }
        if (!allowedRoles.includes(req.user.role)) {
            res.status(403).json({
                error: 'Permisos insuficientes',
                requiredRoles: allowedRoles,
                userRole: req.user.role,
            });
            return;
        }
        next();
    };
};
/**
 * Middleware to require PROFESOR role
 */
export const requireProfesor = requireRole('PROFESOR', 'ADMIN');
/**
 * Middleware to require ADMIN role
 */
export const requireAdmin = requireRole('ADMIN');
/**
 * Check if user is a profesor or admin
 */
export const isProfesorOrAdmin = (role) => {
    return role === 'PROFESOR' || role === 'ADMIN';
};
/**
 * Check if user is a padre
 */
export const isPadre = (role) => {
    return role === 'PADRE';
};
export default { requireRole, requireProfesor, requireAdmin, isProfesorOrAdmin, isPadre };
