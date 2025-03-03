import requests
import warnings
import threading
import time
from flask import Flask, request
from student import *
from requests.packages import urllib3
from utils.aes import *
from middleware import *
import pymysql

urllib3.disable_warnings()
warnings.filterwarnings("ignore")

app = Flask(__name__)
app.before_request(before_request)
app.after_request(after_request)

def closeConn(conn, cursor):
  conn.commit()
  cursor.close()
  conn.close()

@app.route('/test', methods=['GET', 'POST'])
def test():
  return {
    "suc": True,
    "msg": "helloworld"
  }

@app.route('/login', methods=['POST'])
def login():
  cursor = request.json['cursor']
  conn = request.json['conn']
  try: 
    token = request.json['token']
    data = decodeToken(token)
    mobile = data['mobile']
    password = data['password']
    data = None
    try:
      data = Student.preLogin(mobile, password)
    except Exception:
      closeConn(conn, cursor)
      return {
        "suc": False,
        "msg": "账号或密码错误"
      }
    cursor.execute("SELECT permission FROM UserPerm WHERE mobile = %s", (mobile,))
    if cursor.rowcount == 0 or cursor.fetchone()['permission'] == 0:
      closeConn(conn, cursor)
      return {
        "suc": False,
        "msg": "账号未授权"
      }
    cursor.execute("select uid from UserInfo where uid = %s", (data['uid'],))
    if cursor.rowcount > 0: # 注册过
      cursor.execute("update UserInfo set name = %s, avatar = %s, token = %s where uid = %s", (data['name'], data['avatar'], str(token), int(data['uid'])))
      closeConn(conn, cursor)
      return {
        "suc": True,
        "msg": "登录成功",
        "data": {
          "uid": data['uid'],
          "name": data['name'],
          "avatar": data['avatar']
        }
      }
    # 未注册过
    cursor.execute("insert into UserInfo (uid, avatar, name, mobile, token) values (%s, %s, %s, %s, %s)", (int(data['uid']), data['avatar'], data['name'], str(mobile), str(token)))
    stu = Student(mobile, password)
    stu.syncAllCoursesToDatabase(cursor)
    closeConn(conn, cursor)
    return {
      "suc": True,
      "msg": "注册成功",
      "data": {
        "uid": data['uid'],
        "name": data['name'],
        "avatar": data['avatar']
      }
    }
  except Exception as e:
    closeConn(conn, cursor)
    return {
      "suc": False,
      "msg": str(e),
    }

@app.route('/getAllCourse', methods=['POST'])
def getAllCourse():
  cursor = request.json['cursor']
  conn = request.json['conn']
  try:
    student = request.json['student'] # type: Student
    sync = request.json.get('sync', False)
    if sync:
      student.syncAllCoursesToDatabase(cursor)
    courses = student.getAllCoursesFromDatabase(cursor)
    closeConn(conn, cursor)
    return {
      "suc": True,
      "msg": "获取成功",
      "data": courses
    }
  except Exception as e:
    closeConn(conn, cursor)
    return {
      "suc": False,
      "msg": str(e),
    }

@app.route('/setCourseSelectState', methods=['POST'])
def setCourseSelectState():
  cursor = request.json['cursor']
  conn = request.json['conn']
  try:
    courses = request.json['courses']
    student = request.json['student'] # type: Student
    student.setCourseSelectState(cursor, courses)
    closeConn(conn, cursor)
    return {
      "suc": True,
      "msg": "设置成功"
    }
  except Exception as e:
    closeConn(conn, cursor)
    return {
      "suc": False,
      "msg": str(e),
    }

@app.route('/getSelectedCourseAndActivityList', methods=['POST'])
def getCourseAndActivityList():
  cursor = request.json['cursor']
  conn = request.json['conn']
  try:
    student = request.json['student'] # type: Student
    selectedCourseList = student.getSelectedCoursesFromDatabase(cursor)
    for course in selectedCourseList:
      actives = student.getActivesFromCourse(cursor, course)
      course['actives'] = actives
    selectedCourseList = sorted(selectedCourseList, key=lambda x: x['actives'][0]['startTime'] if x['actives'] else -1, reverse=True)
    closeConn(conn, cursor)
    return {
      'suc': True,
      'msg': '获取成功',
      'data': selectedCourseList
    }
  except Exception as e:
    closeConn(conn, cursor)
    return {
      "suc": False,
      "msg": str(e),
    }

@app.route('/getClassmates', methods=['POST'])
def getClassmates():
  cursor = request.json['cursor']
  conn = request.json['conn']
  try:
    student = request.json['student'] # type: Student
    classId = request.json['classId']
    courseId = request.json['courseId']
    classmates = student.getClassmates(cursor, classId, courseId)
    closeConn(conn, cursor)
    return {
      'suc': True,
      'msg': '获取成功',
      'data': classmates
    }
  except Exception as e:
    closeConn(conn, cursor)
    return {
      "suc": False,
      "msg": str(e),
    }


@app.route('/sign', methods=['POST'])
def sign():
  cursor = request.json['cursor']
  conn = request.json['conn']
  try:
    selfStudent = request.json['student'] # type: Student
    uid = request.json['uid']
    cursor.execute("select token from UserInfo where uid = %s", (uid))
    token = cursor.fetchone()['token']
    data = decodeToken(token)
    student = Student(data['mobile'], data['password'])
    fixedParams = request.json['fixedParams']
    specialParams = request.json['specialParams']
    signType = request.json['signType']
    try:
      if (signType == SignTypeEnum.QRCode.value):
        student.preSign(fixedParams, specialParams['c'], specialParams['enc'])
      else:
        student.preSign(fixedParams)
      result = student.sign(signType, fixedParams, specialParams)
    except Exception as e:
      closeConn(conn, cursor)
      return {
        'suc': False,
        'msg': str(e)
      }
    if (result != "success"):
      closeConn(conn, cursor)
      return {
        'suc': False,
        'msg': result
      }
    line = cursor.execute("insert into SignRecord (uid, activeId, source, signTime) values (%s, %s, %s, %s)", (student.uid, fixedParams['activeId'], selfStudent.uid, int(time.time())))
    if line == 0:
      closeConn(conn, cursor)
      return {
        'suc': False,
        'msg': '签到记录插入失败'
      }
    closeConn(conn, cursor)
    return {
      'suc': True,
      'msg': '签到成功'
    }
  except Exception as e:
    closeConn(conn, cursor)
    return {
      "suc": False,
      "msg": str(e),
    }

@app.route('/getSignStateFromDataBase', methods=['POST'])
def getSignStateFromDataBase():
  cursor = request.json['cursor']
  conn = request.json['conn']
  try:
    student = request.json['student'] # type: Student
    activeId = request.json['activeId']
    classmates = request.json['classmates']
    res = student.getSignStateFromDataBase(cursor, activeId, classmates)
    closeConn(conn, cursor)
    return {
      'suc': True,
      'msg': '获取成功',
      'data': res
    }
  except Exception as e:
    closeConn(conn, cursor)
    return {
      "suc": False,
      "msg": str(e),
    }
  
if __name__ == "__main__":
  app.run(host='0.0.0.0', debug=True, port=3030)
