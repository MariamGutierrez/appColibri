from requests import session
from flask import Blueprint, redirect, url_for, session

authentication_blueprint = Blueprint("authentication", __name__)

@authentication_blueprint.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login_page'))

blueprint = authentication_blueprint