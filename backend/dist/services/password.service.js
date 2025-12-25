import bcrypt from 'bcrypt';
const SALT_ROUNDS = parseInt(process.env.BCRYPT_ROUNDS || '12');
export class PasswordService {
    /**
     * Hash a password using bcrypt
     */
    static async hash(password) {
        return bcrypt.hash(password, SALT_ROUNDS);
    }
    /**
     * Verify a password against a hash
     */
    static async verify(password, hash) {
        return bcrypt.compare(password, hash);
    }
    /**
     * Validate password requirements
     */
    static validate(password) {
        const errors = [];
        if (password.length < 8) {
            errors.push('La contraseña debe tener al menos 8 caracteres');
        }
        if (!/[A-Z]/.test(password)) {
            errors.push('La contraseña debe contener al menos una letra mayúscula');
        }
        if (!/[a-z]/.test(password)) {
            errors.push('La contraseña debe contener al menos una letra minúscula');
        }
        if (!/[0-9]/.test(password)) {
            errors.push('La contraseña debe contener al menos un número');
        }
        return { valid: errors.length === 0, errors };
    }
}
export default PasswordService;
