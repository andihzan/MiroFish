from flask import request, jsonify
from datetime import datetime, timedelta
import jwt
from ..config import Config
from . import auth_bp

@auth_bp.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'error': 'Invalid request'}), 400
            
        password = data.get('password')
        if not password:
            return jsonify({'success': False, 'error': 'Password is required'}), 400
            
        if password == Config.APP_PASSWORD:
            # Generate JWT Token, valid for 24 hours
            token = jwt.encode({
                'exp': datetime.utcnow() + timedelta(days=1),
                'iat': datetime.utcnow(),
                'sub': 'admin'
            }, Config.JWT_SECRET_KEY, algorithm='HS256')
            
            return jsonify({
                'success': True,
                'token': token
            })
        else:
            return jsonify({'success': False, 'error': 'Invalid password'}), 401
            
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500
