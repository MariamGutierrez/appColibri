@authentication_blueprint.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login_page'))