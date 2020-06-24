using OpenCV
const cv = OpenCV
size0 = Int32(300)
# take the model from https://github.com/opencv/opencv_extra/tree/master/testdata/dnn
net = cv.dnn_DetectionModel("/home/archit/Downloads/opencv_face_detector.pbtxt",
                     "/home/archit/Downloads/opencv_face_detector_uint8.pb")

cv.setPreferableTarget(net, cv.DNN_TARGET_CPU)
cv.setInputMean(net, (104, 177, 123))
cv.setInputScale(net, 1.)
cv.setInputSize(net, size0, size0)

cap = cv.VideoCapture(Int32(0))
while true
    ok, frame = cv.read(cap)
    if ok == false
        break
    end
    classIds, confidences, boxes = cv.detect(net, frame, confThreshold=Float32(0.5))
    for i in 1:size(boxes,1)
        confidence = confidences[i]
        x0 = Int32(boxes[i].x)
        y0 = Int32(boxes[i].y)
        x1 = Int32(boxes[i].x+boxes[i].width)
        y1 = Int32(boxes[i].y+boxes[i].height)
        cv.rectangle(frame, cv.Point{Int32}(x0, y0), cv.Point{Int32}(x1, y1), (100, 255, 100); thickness = Int32(5))
        label = "face: " * string(confidence)
        lsize, bl = cv.getTextSize(label, cv.FONT_HERSHEY_SIMPLEX, 0.5, Int32(1))
        cv.rectangle(frame, cv.Point{Int32}(x0,y0), cv.Point{Int32}(x0+lsize.width, y0+lsize.height+bl), (100,255,100); thickness = Int32(-1))
        cv.putText(frame, label, cv.Point{Int32}(x0, y0 + lsize.height),
        cv.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 0); thickness = Int32(1), lineType = cv.LINE_AA)
    end
    cv.imshow("detections", frame)
    if cv.waitKey(Int32(30)) >= 0
        break
    end
end