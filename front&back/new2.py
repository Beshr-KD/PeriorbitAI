from flask import Flask, redirect, url_for, render_template, request

app = Flask(__name__)

# import run_periorbitAI

@app.route("/")
def welcome_page():
    return render_template("form.html")

# @app.route('/AI')
# def AI():
#     file = open(r'../../run_periorbitAI.py', 'r').read()
#     exec(file)
#     # run_periorbitAI.your_function_in_the_module()
#     return render_template("index.html")

@app.route("/index.html", methods=['POST'])
def response():
    img = request.form["img"]
    return render_template("index.html")
 
if __name__ == "__main__":
    app.run()
