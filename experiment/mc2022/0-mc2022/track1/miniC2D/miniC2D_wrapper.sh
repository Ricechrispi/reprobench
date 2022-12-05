#!/usr/bin/env bash
#set -x
# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

echo "c o CALLSTR $@"

custom_conda_location="$HOME/miniconda3"
conda_env_name="rb" # name of conda environment, default should be "rb" 

for i in "$@"
do
case $i in
    -t=*|--tmpdir=*) #TODO: remove/incorp. some of these arguments?
    PTMPDIR="${i#*=}"
    shift # past argument=value
    ;;
    -r=*|--maxrss=*)
    PMAXRSS="${i#*=}"
    shift # past argument=value
    ;;
    -d=*|--maxtmp=*)
    PMAXTMP="${i#*=}"
    shift # past argument=value
    ;;
    -w=*|--timeout=*)
    PTIMEOUT="${i#*=}"
    shift # past argument=value
    ;;
    -a=*|--algo=*)
    ALGO="${i#*=}"
    shift
    ;;
    -p=|--pfile=*)
    PFILE="${i#*=}"
    shift
    ;;
    -i=*|--instance=*)
    INSTANCE="${i#*=}"
    shift
    ;;
    --default)
    DEFAULT=YES
    shift # past argument with no value
    ;;
    *)
          # unknown option
    ;;
esac
done
shift $((OPTIND))

echo "c o =============== TEST CMDLINE ARGS ========================="
echo "c o CMDLINE TMPDIR = ${PTMPDIR}"
echo "c o CMDLINE PMAXTMP = ${PMAXTMP}"
echo "c o CMDLINE MAXRSS = ${PMAXRSS}"
echo "c o CMDLINE TIMEOUT = ${PTIMEOUT}"

echo "c o =============== TEST ENV VARS ==========================="
echo "c o ENV TMPDIR = ${TMPDIR}"
echo "c o ENV PMAXTMP = ${MAXTMP}"
echo "c o ENV MAXRSS = ${MAXRSS}"
echo "c o ENV TIMEOUT = ${TIMEOUT}"
echo "c o ENV ALGO = ${ALGO}"
echo "c o ENV PFILE = ${PFILE}"
echo "c o ENV INSTANCE = ${INSTANCE}"

echo "c o ================= SET PRIM INTRT HANDLING ==============="
function interrupted(){
  echo "c o Sending kill to subprocess"
  kill -TERM $PID
  echo "c o Removing tmp files"
  [ ! -z "$prec_tmpfile" ] && rm $prec_tmpfile
  [ ! -z "$tmpfile" ] && rm $tmpfile
}
function finish {
  # Your cleanup code here
  echo "c o Removing tmp files"
  [ ! -z "$prec_tmpfile" ] && rm $prec_tmpfile
  [ ! -z "$tmpfile" ] && rm $tmpfile
}
trap finish EXIT
trap interrupted TERM
trap interrupted INT

echo "c o ================= POS CMDLINE ARGS ==============="
echo "c o $@"


echo "c o ================= Changing directory to output directory ==============="
#cd "$(dirname "$0")" || (echo "Could not change directory to $0. Exiting..."; exit 1)
cd "/mnt/hosts/cobra-submit/mnt/vg01/lv01/home/cpriesne/master_project" || (echo "Could not change directory to .../master_project. Exiting..."; exit 1)

BIN_DIR="/mnt/hosts/cobra-submit/mnt/vg01/lv01/home/cpriesne/master_project"

echo "c o ================= Preparing tmpfiles ==============="
#prec_tmpfile=$(mktemp ${PTMPDIR}/result.XXXXXX)
#tmpfile=$(mktemp ${PTMPDIR}/result.XXXXXX)
prec_tmpfile=$(mktemp /run/shm/result.XXXXXX)
tmpfile=$(mktemp /run/shm/result.XXXXXX)
#TODO: why did the other version not work? crashes because of it.

#echo "c o ================= Running Preprocessor ==============="
#preproc_cmd=$BIN_DIR"/BiPe -preproc $1"
#echo "c o PRE=$preproc_cmd"
# you asked for for c t mc instead of the suggested ct mc
# so bugfixing the c t mc problem with some solvers;
#sed -i '/^c t/d' $1

#$preproc_cmd > $prec_tmpfile &
#PID=$!
#wait $PID
#exit_code=$?

#if [ $exit_code -eq "0" ] ; then
#  echo "c o ================= Preprocessor Successful ==============="
#  filename=$prec_tmpfile
#else
#  echo "c o ================= Preprocessor Failed using input file ==============="
#  filename=$1
#fi

echo "c o ================== Activating Conda environment ======================"
echo "using custom conda location"
myconda="$custom_conda_location"
#>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('$myconda/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
	eval "$__conda_setup"
else
	if [ -f "$myconda/etc/profile.d/conda.sh" ]; then
		. "$myconda/etc/profile.d/conda.sh"
	else
		export PATH="$myconda/bin:$PATH"
	fi
fi
unset __conda_setup
# <<< conda initialize <<<
conda activate "$conda_env_name"


echo "c o ================= Running Solver ==============="
cmd="python benchmark_runner.py $ALGO -instance $INSTANCE -param_file $PFILE"
myenv="TMPDIR=$TMPDIR"
echo "c o SOLVERCMD=$cmd"

env $myenv $cmd > $tmpfile &
PID=$!
wait $PID
exit_code=$?
echo "c solver_wrapper: ==============================="
echo "c solver_wrapper: Solver finished with exit code="$exit_code
echo "c f RET="$exit_code

echo "c output of solver:"
cat $tmpfile

#result=$(cat $tmpfile | grep "^s " | awk '{print $2}')
#if [ $result -eq "0" ] ; then
#  echo "s UNSATISFIABLE"
#  echo "c s $PTASK"
#  echo "c s log10-estimate inf"
#  echo "c s exact quadruple int 0"
#else
#  echo "s SATISFIABLE"
#  echo "c type $PTASK"
#  #let's play codegolf
#  log10=$(echo $result | python3 -c 'import sys; import math; print(math.log10(int(sys.stdin.readline())));')
#  echo "c s log10-estimate $log10"
#  echo "c s exact quadruple int $result"
#fi

exit $exit_code
