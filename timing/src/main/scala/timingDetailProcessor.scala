package timing

import scala.math._
import scala.util._
import scala.io.Source
import scala.util.matching.Regex
import scala.util.Using
import scala.util.Try
import scala._
import scala.collection.mutable
import java.io._
import java.util.Date
import scala.language.postfixOps
import sys.process._
import sys._

class TimingDetailParser(val slack: Double) extends FileIOUtils {
    val keyPointNamePattern = "Key Point Name \"(.*)\"".r.unanchored
    val startPointPattern = "Startpoint: (.*)\\Z".r.unanchored
    val endPointPattern = "Endpoint: (.*)\\Z".r.unanchored
    val slackPattern = "slack.*?(-?\\d+\\.\\d+)".r.unanchored

    case class Path(
        val startPoint: Option[String] = None,
        val endPoint: Option[String] = None,
        val slack: Option[Double] = None
    ) {
        def get: (String, String, Double) =
            (startPoint.getOrElse("none"),
             endPoint.getOrElse("none"),
             slack.getOrElse(0.0))
        override def toString(): String = {
            val (start, end, slack) = get
            s"start = $start\nend   = $end\nslack = $slack"
        }
    }
    type KeyPoint = Tuple2[String, List[Path]]
    type KeyPointRecord = List[KeyPoint]

    def getLines(s: scala.io.BufferedSource): Iterator[String] = s.getLines()
    def makeRecord(it: Iterator[String], r: KeyPointRecord = List()): KeyPointRecord = {
        def makeKeyPointRecord(rec: KeyPoint, path: Path = Path(), hasName: Boolean = true): (KeyPoint, Option[String]) = {
            val (name, paths) = rec
            if (it.hasNext) {
                val next = it.next
                next match {
                    case startPointPattern(start) => {
                        assert(path.startPoint.isEmpty)
                        makeKeyPointRecord(rec, path.copy(startPoint=Some(start)))
                    }
                    case endPointPattern(end) => {
                        assert(path.endPoint.isEmpty)
                        makeKeyPointRecord(rec, path.copy(endPoint=Some(end)))
                    }
                    case slackPattern(slack) => {
                        assert(path.slack.isEmpty)
                        // println(s"slack is $slack")
                        val thisPath = path.copy(slack=Some(slack.toDouble))
                        makeKeyPointRecord((name, thisPath :: paths), Path())
                    }
                    case keyPointNamePattern(newName) => { // new keypoint, pass out name
                        if (hasName) (rec, Some(newName))
                        else makeKeyPointRecord((newName, paths))
                    }
                    case _ => makeKeyPointRecord(rec, path, hasName)
                }
            }
            else {(rec, None)}
        }
        def iter(r: KeyPointRecord, keyPointName: Option[String] = None): KeyPointRecord = {
            val emptyKeyPoint: KeyPoint = ("", List())
            val (kp, newName) = 
                keyPointName match {
                    case None => makeKeyPointRecord(emptyKeyPoint, Path(), false)
                    case Some(name) => {
                        val newKeyPoint: KeyPoint = (name, List())
                        makeKeyPointRecord(newKeyPoint, Path())
                    }
                }
            newName match {
                case None => kp :: r
                case Some(newName) => iter(kp :: r, Some(newName))
            }
        }
        iter(List(), None)
    }

    def makeRecordFromFile(f: String): KeyPointRecord = {
        readFile(f, s => makeRecord(getLines(s))).get
    }

    // def totalDelayComp(p1: Path, p2: Path) = (p1._2._1 + p1._2._2) > (p2._2._1 + p2._2._2)
    // def maxDelayComp(p1: Path, p2: Path) = max(p1._2._1, p1._2._2) > max(p2._2._1, p2._2._2)

    // def totalDelayExceedsLimit(p: Path) = (p._2._1 + p._2._2) > 2*cycle
    // def maxDelayExceedsLimit(p: Path) = p._2._1 > cycle || p._2._2 > cycle
    
    // def sortWithTotalDelay(m: List[Path]) = m.sortWith(totalDelayComp).filter(totalDelayExceedsLimit)
    // def sortWithMaxDelay(m: List[Path]) = m.sortWith(maxDelayComp).filter(maxDelayExceedsLimit)

    def showKeyPoints(m: KeyPointRecord, violated: Boolean = true, max_slack: Double=slack) = {
        // only output those paths who has violated paths
        val output_m =
            m map {
                case (name, paths) => (name, paths.filter(violated && _.get._3 < max_slack))
            }
        val has_paths_m = output_m.filter(!_._2.isEmpty)
        if (has_paths_m.isEmpty) println(s"No paths has slack more than $max_slack")
        else has_paths_m.foreach {
            case (name, paths) => {
                println("-----------------------------KEYPOINT------------------------------")
                println(s"$name:")
                paths.zipWithIndex.foreach {
                    case (p, i) => {
                        println(s"path $i")
                        println(p)
                        println()
                    }
                }
                println("")
            }
        }
    }
}

trait TDPArgParser {
    type OptionMap = Map[String, Option[String]]

    val usage = """
        timingDetailProcessor
        Usage: mill timing.runMain vme.TDPTest [OPTION...]
            -s, --source   the timing detail you would like to extract
                           default: none
                           MUST BE SPECIFIED
            --slack        paths with slack more than this value will be printed out
                           default: 0.0(ns)
            -h, --help     print this help info
      """

    def parse(args: List[String]) = {
        def nextOption(map: OptionMap, l: List[String]): OptionMap = {
            def isSwitch(s : String)= (s(0) == '-')
            l match {
                case Nil => map
                case ("--help" | "-h") :: tail => {
                    println(usage)
                    sys.exit()
                    map
                }
                case ("--source" | "-s") :: file :: tail =>
                    nextOption(map ++ Map("source" -> Some(file)), tail)
                case ("--slack") :: slack :: tail =>
                    nextOption(map ++ Map("slack" -> Some(slack)), tail)
                // this should always be the last argument, since it is length variable
                case s :: tail => {
                    if (isSwitch(s)) println(s"unexpected argument $s")
                    nextOption(map, tail)
                }
            }
        }
        nextOption(Map("source" -> None, "slack" -> None), args)
    }

    

    def wrapParams(args: Array[String]): (String, Double) = {
        val argL = args.toList
        val paramMap = parse(argL)
        def noSource = {
            println("you have to specify a timing detail file!")
            println(usage)
            sys.exit()
            ""
        }
        def slackToDouble(d: String): Double = Try(d.toDouble).getOrElse(0.0)
        val source = paramMap("source").getOrElse(noSource)
        val slack  = slackToDouble(paramMap("slack").getOrElse("0.0"))
        (source, slack)
    }
}

object TDPTest extends TDPArgParser {
    def main(args: Array[String]): Unit = {
        val (source, slack) = wrapParams(args) // TODO: output to file
        val tdp = new TimingDetailParser(slack)
        val l = tdp.makeRecordFromFile(source)
        tdp.showKeyPoints(l.reverse)
    }
}